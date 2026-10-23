import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application.Storage;
import Toybox.Attention;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// In-memory workout. A phone message can replace the baked-in sample.
// Slots are one set each, in workout order, so previous/next walks
// sets and exercises with the same control.
class Session {
    var locked as Boolean = false;
    var dateKey as String = "sample";
    var weightUnit as String = "lb";
    var restPreset as Number = 90;
    var restRemaining as Number = 0;
    var restPaused as Boolean = false;
    var restEndsAt as Number = 0;
    var exitAfterRest as Boolean = false;
    var activity as ActivityRecording.Session? = null;
    var activitySaved as Boolean = false;
    var index as Number = 0;
    var slots as Array<Dictionary> = [] as Array<Dictionary>;
    var timer as Timer.Timer = new Timer.Timer();
    var restEndedOnItsOwn as Boolean = false;

    function initialize() {
        loadSample();
    }

    function loadSample() as Void {
        locked = false;
        dateKey = "sample";
        weightUnit = "lb";
        restPreset = 90;
        restRemaining = 0;
        restPaused = false;
        index = 0;
        slots = [
            makeSlot("bench-press", "Bench Press", 0, 3, 8, 135),
            makeSlot("bench-press", "Bench Press", 1, 3, 8, 135),
            makeSlot("bench-press", "Bench Press", 2, 3, 6, 145),
            makeSlot("barbell-row", "Barbell Row", 0, 3, 8, 115),
            makeSlot("barbell-row", "Barbell Row", 1, 3, 8, 115),
            makeSlot("barbell-row", "Barbell Row", 2, 3, 8, 125),
            makeSlot("back-squat", "Back Squat", 0, 3, 5, 185),
            makeSlot("back-squat", "Back Squat", 1, 3, 5, 185),
            makeSlot("back-squat", "Back Squat", 2, 3, 3, 205)
        ] as Array<Dictionary>;
    }

    // Phone payload (Connect IQ Mobile SDK dictionary, not a JSON string):
    // {
    //   version, locked, dateKey, weightUnit, restSeconds,
    //   slots: [{ exerciseId, exerciseName, setIndex, setCount, reps, weight, done }]
    // }
    // If slots is missing, one exercise is expanded from exerciseName,
    // targetReps, targetWeightDisplay, setCount, and currentSetIndex.
    function applyPhone(data as Dictionary) as Void {
        if (data["locked"] == true) {
            locked = true;
            stopRest();
            if (anySetDone()) {
                saveActivity();
            } else {
                discardActivity();
            }
            return;
        }
        locked = false;
        if (data["dateKey"] instanceof String) {
            dateKey = data["dateKey"] as String;
        }
        if (data["weightUnit"] instanceof String) {
            weightUnit = data["weightUnit"] as String;
        }
        if (data["restSeconds"] != null) {
            restPreset = clampRest(asInt(data["restSeconds"]));
        }
        restRemaining = 0;
        stopRest();
        if (data["slots"] instanceof Array) {
            var incoming = data["slots"] as Array;
            var next = [] as Array<Dictionary>;
            for (var i = 0; i < incoming.size(); i++) {
                if (incoming[i] instanceof Dictionary) {
                    next.add(normalizeSlot(incoming[i] as Dictionary));
                }
            }
            if (next.size() > 0) {
                slots = next;
                index = firstOpen();
                ensureActivity();
            }
            return;
        }
        var name = "Exercise";
        if (data["exerciseName"] instanceof String) {
            name = data["exerciseName"] as String;
        }
        var id = "exercise";
        if (data["exerciseId"] instanceof String) {
            id = data["exerciseId"] as String;
        }
        var count = asInt(data["setCount"]);
        if (count < 1) {
            count = 1;
        }
        var current = asInt(data["currentSetIndex"]);
        var reps = asInt(data["targetReps"]);
        var weight = asInt(data["targetWeightDisplay"]);
        var built = [] as Array<Dictionary>;
        for (var n = 0; n < count; n++) {
            var slot = makeSlot(id, name, n, count, reps, weight);
            slot["done"] = n < current;
            built.add(slot);
        }
        slots = built;
        if (current < 0) {
            current = 0;
        }
        if (current >= count) {
            current = count - 1;
        }
        index = current;
        ensureActivity();
    }

    function current() as Dictionary? {
        if (index < 0 || index >= slots.size()) {
            return null;
        }
        return slots[index];
    }

    function exerciseName() as String {
        var slot = current();
        if (slot == null) {
            return "Workout";
        }
        return slot["exerciseName"] as String;
    }

    function setLabel() as String {
        var slot = current();
        if (slot == null) {
            return "No sets";
        }
        var number = (slot["setIndex"] as Number) + 1;
        var count = slot["setCount"] as Number;
        var label = "Set " + number.toString() + " of " + count.toString();
        if (slot["done"] == true) {
            label = label + "  logged";
        }
        return label;
    }

    function weightLabel() as String {
        var slot = current();
        if (slot == null) {
            return "0 " + weightUnit;
        }
        return (slot["weight"] as Number).toString() + " " + weightUnit;
    }

    function repsLabel() as String {
        var slot = current();
        if (slot == null) {
            return "0 reps";
        }
        return (slot["reps"] as Number).toString() + " reps";
    }

    function restLabel() as String {
        if (restRemaining > 0 && restPaused) {
            return "Paused " + formatClock(restRemaining);
        }
        var seconds = restPreset;
        if (restRemaining > 0) {
            seconds = restRemaining;
        }
        return "Rest " + formatClock(seconds);
    }

    function canMove(delta as Number) as Boolean {
        var next = index + delta;
        return next >= 0 && next < slots.size();
    }

    function move(delta as Number) as Void {
        if (!canMove(delta)) {
            return;
        }
        index = index + delta;
        cueStep();
        WatchUi.requestUpdate();
    }

    function adjustWeight(delta as Number) as Void {
        var slot = current();
        if (slot == null) {
            return;
        }
        var weight = (slot["weight"] as Number) + delta;
        if (weight < 0) {
            weight = 0;
        }
        slot["weight"] = weight;
        cueStep();
        send("adjustSet");
        WatchUi.requestUpdate();
    }

    function adjustReps(delta as Number) as Void {
        var slot = current();
        if (slot == null) {
            return;
        }
        var reps = (slot["reps"] as Number) + delta;
        if (reps < 0) {
            reps = 0;
        }
        slot["reps"] = reps;
        cueStep();
        send("adjustSet");
        WatchUi.requestUpdate();
    }

    function adjustRest(delta as Number) as Void {
        var next = clampRest(restPreset + delta);
        var change = next - restPreset;
        if (change == 0) {
            return;
        }
        restPreset = next;
        if (restRemaining > 0 && restPaused == false && restEndsAt > 0) {
            var ends = restEndsAt + change;
            var now = unixNow();
            if (ends < now) {
                ends = now;
            }
            if (ends > now + 300) {
                ends = now + 300;
            }
            restEndsAt = ends;
        }
        if (restRemaining > 0) {
            var left = restRemaining + change;
            if (left < 0) {
                left = 0;
            }
            if (left > 300) {
                left = 300;
            }
            restRemaining = left;
            if (left == 0) {
                timer.stop();
                restPaused = false;
                restEndsAt = 0;
            }
        }
        persistRest();
        cueStep();
        send("setRest");
        WatchUi.requestUpdate();
    }

    function toggleSet() as Void {
        var slot = current();
        if (slot == null) {
            return;
        }
        if (slot["done"] == true) {
            undoSet();
        } else {
            completeSet();
        }
    }

    function completeSet() as Void {
        var slot = current();
        if (slot == null || slot["done"] == true) {
            return;
        }
        slot["done"] = true;
        send("completeSet");
        cueSetDone();
        startRest();
        if (index + 1 < slots.size()) {
            index = index + 1;
        }
        WatchUi.requestUpdate();
    }

    function undoSet() as Void {
        var slot = current();
        if (slot == null || slot["done"] != true) {
            return;
        }
        slot["done"] = false;
        send("undoSet");
        cueUndo();
        WatchUi.requestUpdate();
    }

    function startRest() as Void {
        restEndedOnItsOwn = false;
        restPaused = false;
        restRemaining = restPreset;
        restEndsAt = unixNow() + restPreset;
        timer.stop();
        timer.start(method(:tickRest), 1000, true);
        persistRest();
    }

    function stopRest() as Void {
        timer.stop();
        restRemaining = 0;
        restPaused = false;
        restEndsAt = 0;
        persistRest();
    }

    function pauseRest() as Void {
        if (restRemaining <= 0 || restPaused) {
            return;
        }
        syncRestClock(true);
        if (restRemaining <= 0) {
            return;
        }
        restPaused = true;
        restEndsAt = 0;
        timer.stop();
        persistRest();
        cueStep();
        WatchUi.requestUpdate();
    }

    function resumeRest() as Void {
        if (restRemaining <= 0 || restPaused == false) {
            return;
        }
        restPaused = false;
        restEndsAt = unixNow() + restRemaining;
        timer.stop();
        timer.start(method(:tickRest), 1000, true);
        persistRest();
        cueStep();
        WatchUi.requestUpdate();
    }

    function cancelRest() as Void {
        if (restRemaining <= 0) {
            return;
        }
        var leaving = exitAfterRest;
        exitAfterRest = false;
        stopRest();
        cueStep();
        if (leaving) {
            leaveNow();
            return;
        }
        WatchUi.requestUpdate();
    }

    function tickRest() as Void {
        syncRestClock(false);
    }

    // Remaining time is an absolute end timestamp so a dimmed screen,
    // a slow timer, or a relaunch still shows the real countdown.
    // Connect IQ cannot vibrate at an arbitrary second after this
    // process is killed, so Home waits here until the alert fires.
    function syncRestClock(fromDraw as Boolean) as Void {
        if (restPaused || restEndsAt <= 0) {
            return;
        }
        var left = restEndsAt - unixNow();
        if (left <= 0) {
            restEndsAt = 0;
            restRemaining = 0;
            restPaused = false;
            timer.stop();
            restEndedOnItsOwn = true;
            persistRest();
            cueRestDone();
            if (exitAfterRest) {
                exitAfterRest = false;
                leaveNow();
            } else if (fromDraw == false) {
                WatchUi.requestUpdate();
            }
            return;
        }
        if (left != restRemaining) {
            restRemaining = left;
            if (fromDraw == false) {
                WatchUi.requestUpdate();
            }
        }
    }

    function restoreRest() as Void {
        var paused = Storage.getValue("lbRestPaused");
        var pausedLeft = 0;
        if (paused instanceof Number) {
            pausedLeft = paused as Number;
        }
        if (pausedLeft > 0) {
            restPaused = true;
            restRemaining = pausedLeft;
            restEndsAt = 0;
            return;
        }
        var ends = Storage.getValue("lbRestEnds");
        var endsAt = 0;
        if (ends instanceof Number) {
            endsAt = ends as Number;
        }
        if (endsAt <= 0) {
            return;
        }
        var left = endsAt - unixNow();
        if (left <= 0) {
            Storage.deleteValue("lbRestEnds");
            cueRestDone();
            return;
        }
        restEndsAt = endsAt;
        restRemaining = left;
        restPaused = false;
        timer.stop();
        timer.start(method(:tickRest), 1000, true);
    }

    function persistRest() as Void {
        if (restPaused && restRemaining > 0) {
            Storage.setValue("lbRestPaused", restRemaining);
            Storage.deleteValue("lbRestEnds");
            return;
        }
        Storage.deleteValue("lbRestPaused");
        if (restEndsAt > 0) {
            Storage.setValue("lbRestEnds", restEndsAt);
        } else {
            Storage.deleteValue("lbRestEnds");
        }
    }

    function ensureActivity() as Void {
        if (locked) {
            return;
        }
        if (!(Toybox has :ActivityRecording)) {
            return;
        }
        var recording = activity;
        if (recording != null) {
            if (recording.isRecording()) {
                return;
            }
        }
        try {
            recording = ActivityRecording.createSession({
                :name => "LiftBig",
                :sport => Activity.SPORT_TRAINING,
                :subSport => Activity.SUB_SPORT_STRENGTH_TRAINING
            });
            recording.start();
            activity = recording;
            activitySaved = false;
        } catch (ex) {
        }
    }

    function saveActivity() as Void {
        var recording = activity;
        if (recording == null || activitySaved) {
            return;
        }
        try {
            if (recording.isRecording()) {
                recording.stop();
            }
            recording.save();
            activitySaved = true;
        } catch (ex) {
        }
        activity = null;
    }

    function discardActivity() as Void {
        var recording = activity;
        if (recording == null) {
            return;
        }
        try {
            if (recording.isRecording()) {
                recording.stop();
            }
            recording.discard();
        } catch (ex) {
        }
        activity = null;
        activitySaved = false;
    }

    function anySetDone() as Boolean {
        for (var i = 0; i < slots.size(); i++) {
            if (slots[i]["done"] == true) {
                return true;
            }
        }
        return false;
    }

    function finishWorkout() as Void {
        saveActivity();
        // Best effort only. The iOS Connect IQ listener is not built,
        // so this transmit does not write the iPhone journal.
        send("finishWorkout");
        cueSetDone();
        WatchUi.requestUpdate();
    }

    function requestHome() as Void {
        if (restRemaining > 0) {
            exitAfterRest = true;
            cueStep();
            WatchUi.requestUpdate();
            return;
        }
        leaveNow();
    }

    function leaveNow() as Void {
        exitAfterRest = false;
        stopRest();
        if (anySetDone()) {
            saveActivity();
        } else {
            discardActivity();
        }
        System.exit();
    }

    function send(kind as String) as Void {
        var slot = current();
        if (slot == null || !(Communications has :transmit)) {
            return;
        }
        // completeSet and undoSet send the set on screen, then completeSet
        // advances. adjustSet and setRest describe the set on screen.
        var message = {
            "version" => 1,
            "kind" => kind,
            "dateKey" => dateKey,
            "exerciseId" => slot["exerciseId"],
            "setIndex" => slot["setIndex"],
            "reps" => (slot["reps"] as Number).toString(),
            "weightDisplay" => (slot["weight"] as Number).toString(),
            "weightUnit" => weightUnit,
            "restSeconds" => restPreset
        };
        try {
            Communications.transmit(message, null, new PhoneListener());
        } catch (ex) {
        }
    }

    function firstOpen() as Number {
        for (var i = 0; i < slots.size(); i++) {
            if (slots[i]["done"] != true) {
                return i;
            }
        }
        if (slots.size() == 0) {
            return 0;
        }
        return slots.size() - 1;
    }

    private function clampRest(seconds as Number) as Number {
        if (seconds < 5) {
            return 5;
        }
        if (seconds > 300) {
            return 300;
        }
        return seconds;
    }
}

function makeSlot(id as String, name as String, setIndex as Number, setCount as Number, reps as Number, weight as Number) as Dictionary {
    return {
        "exerciseId" => id,
        "exerciseName" => name,
        "setIndex" => setIndex,
        "setCount" => setCount,
        "reps" => reps,
        "weight" => weight,
        "done" => false
    };
}

function normalizeSlot(raw as Dictionary) as Dictionary {
    var id = "exercise";
    if (raw["exerciseId"] instanceof String) {
        id = raw["exerciseId"] as String;
    }
    var name = "Exercise";
    if (raw["exerciseName"] instanceof String) {
        name = raw["exerciseName"] as String;
    }
    var setCount = asInt(raw["setCount"]);
    if (setCount < 1) {
        setCount = 1;
    }
    var slot = makeSlot(id, name, asInt(raw["setIndex"]), setCount, asInt(raw["reps"]), asInt(raw["weight"]));
    slot["done"] = raw["done"] == true;
    return slot;
}

function asInt(value as Object?) as Number {
    if (value instanceof Number) {
        return value as Number;
    }
    if (value instanceof Float) {
        return (value as Float).toNumber();
    }
    if (value instanceof Long) {
        return (value as Long).toNumber();
    }
    if (value instanceof String) {
        var parsed = (value as String).toNumber();
        if (parsed != null) {
            return parsed;
        }
    }
    return 0;
}

function unixNow() as Number {
    return Time.now().value();
}

function formatClock(seconds as Number) as String {
    if (seconds < 0) {
        seconds = 0;
    }
    var minutes = seconds / 60;
    var remain = seconds % 60;
    var text = remain.toString();
    if (remain < 10) {
        text = "0" + text;
    }
    return minutes.toString() + ":" + text;
}

function cueStep() as Void {
    if (Attention has :vibrate) {
        Attention.vibrate([new Attention.VibeProfile(35, 30)]);
    }
    if (Attention has :playTone) {
        Attention.playTone(Attention.TONE_KEY);
    }
}

function cueSetDone() as Void {
    if (Attention has :vibrate) {
        Attention.vibrate([
            new Attention.VibeProfile(80, 90),
            new Attention.VibeProfile(100, 140)
        ]);
    }
    if (Attention has :playTone) {
        Attention.playTone(Attention.TONE_SUCCESS);
    }
}

function cueUndo() as Void {
    if (Attention has :vibrate) {
        Attention.vibrate([
            new Attention.VibeProfile(50, 40),
            new Attention.VibeProfile(50, 40)
        ]);
    }
    if (Attention has :playTone) {
        Attention.playTone(Attention.TONE_KEY);
    }
}

function cueRestDone() as Void {
    if (Attention has :vibrate) {
        Attention.vibrate([
            new Attention.VibeProfile(100, 180),
            new Attention.VibeProfile(100, 180)
        ]);
    }
    if (Attention has :playTone) {
        Attention.playTone(Attention.TONE_LOUD_BEEP);
    }
}

class PhoneListener extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }

    function onComplete() as Void {
    }

    function onError() as Void {
    }
}
