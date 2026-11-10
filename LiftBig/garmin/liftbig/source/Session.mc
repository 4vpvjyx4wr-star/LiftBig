import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application.Storage;
import Toybox.Attention;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Temporal background events cannot be scheduled sooner than 5 minutes.
const BACKGROUND_REST_FLOOR = 300;

// In-memory workout. A phone message can replace the baked-in sample.
// Slots are one set each, in workout order. The arrows and the back
// button jump to the previous or next exercise. Up and down still
// walk one set at a time.
class Session {
    var locked as Boolean = false;
    var dateKey as String = "sample";
    var weightUnit as String = "lb";
    var restPreset as Number = 90;
    var restRemaining as Number = 0;
    var restPaused as Boolean = false;
    var restEndsAt as Number = 0;
    var soundEnabled as Boolean = true;
    var exitAfterRest as Boolean = false;
    var activity as ActivityRecording.Session? = null;
    var activitySaved as Boolean = false;
    var index as Number = 0;
    var slots as Array<Dictionary> = [] as Array<Dictionary>;
    var timer as Timer.Timer = new Timer.Timer();
    var toneTimer as Timer.Timer = new Timer.Timer();
    var tonesLeft as Number = 0;
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
    //   version, locked, dateKey, weightUnit, restSeconds, restCancelled,
    //   lineup: [{ exerciseId, exerciseName, setIndex, setCount, reps,
    //              weightDisplay, checked }]
    // }
    // Older payloads may still send slots with numeric weight and done.
    // A republish keeps the set on screen and a running rest. Rest stops
    // when the phone sends restCancelled, or when the session locks.
    // If lineup and slots are both missing, one exercise is expanded from
    // exerciseName, targetReps, targetWeightDisplay, setCount, and currentSetIndex.
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
        applyPhoneRest(data);
        var keepId = "";
        var keepSet = -1;
        var shown = current();
        if (shown != null) {
            keepId = shown["exerciseId"] as String;
            keepSet = shown["setIndex"] as Number;
        }
        var list = [] as Array;
        var hasList = false;
        if (data["lineup"] instanceof Array) {
            list = data["lineup"] as Array;
            hasList = true;
        } else if (data["slots"] instanceof Array) {
            list = data["slots"] as Array;
            hasList = true;
        }
        if (hasList) {
            var next = [] as Array<Dictionary>;
            for (var i = 0; i < list.size(); i++) {
                if (list[i] instanceof Dictionary) {
                    next.add(normalizeSlot(list[i] as Dictionary));
                }
            }
            if (next.size() > 0) {
                slots = next;
                index = indexForSlot(keepId, keepSet);
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
        var phoneIndex = asInt(data["currentSetIndex"]);
        var reps = asInt(data["targetReps"]);
        var weight = asInt(data["targetWeightDisplay"]);
        var built = [] as Array<Dictionary>;
        for (var n = 0; n < count; n++) {
            var slot = makeSlot(id, name, n, count, reps, weight);
            slot["done"] = n < phoneIndex;
            built.add(slot);
        }
        slots = built;
        index = indexForSlot(keepId, keepSet);
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
        WatchUi.requestUpdate();
    }

    function allSetsDone() as Boolean {
        if (slots.size() == 0) {
            return false;
        }
        for (var i = 0; i < slots.size(); i++) {
            if (slots[i]["done"] != true) {
                return false;
            }
        }
        return true;
    }

    // First slot of each exercise, in the order those exercises appear.
    // Back from Bench Press set 2 lands on the previous exercise, not set 1.
    function exerciseStarts() as Array<Number> {
        var starts = [] as Array<Number>;
        var seen = [] as Array<String>;
        for (var i = 0; i < slots.size(); i++) {
            var id = slots[i]["exerciseId"] as String;
            if (memberIndex(seen, id) >= 0) {
                continue;
            }
            seen.add(id);
            starts.add(i);
        }
        return starts;
    }

    function exerciseTarget(delta as Number) as Number {
        if (slots.size() == 0 || delta == 0) {
            return -1;
        }
        var starts = exerciseStarts();
        if (starts.size() == 0) {
            return -1;
        }
        var currentId = "";
        if (index >= 0 && index < slots.size()) {
            currentId = slots[index]["exerciseId"] as String;
        }
        var position = 0;
        for (var s = 0; s < starts.size(); s++) {
            var startId = slots[starts[s]]["exerciseId"] as String;
            if (startId.equals(currentId)) {
                position = s;
                break;
            }
        }
        var nextPos = position + delta;
        if (nextPos < 0 || nextPos >= starts.size()) {
            return -1;
        }
        return starts[nextPos];
    }

    function canMoveExercise(delta as Number) as Boolean {
        return exerciseTarget(delta) >= 0;
    }

    function moveExercise(delta as Number) as Void {
        var target = exerciseTarget(delta);
        if (target < 0) {
            return;
        }
        index = target;
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
        var advance = advanceAfterComplete(index);
        if (advance["rest"] == true) {
            startRest();
        }
        var nextIndex = advance["index"] as Number;
        if (nextIndex >= 0 && nextIndex < slots.size()) {
            index = nextIndex;
        }
        WatchUi.requestUpdate();
    }

    // Superset rounds rotate by supersetOrder to the same set number of the
    // next lift. Rest starts only after the last lift in that round.
    function advanceAfterComplete(from as Number) as Dictionary {
        if (from < 0 || from >= slots.size()) {
            return { "index" => from, "rest" => true };
        }
        var slot = slots[from];
        var group = supersetGroup(slot);
        if (group.equals("")) {
            var plain = from;
            if (from + 1 < slots.size()) {
                plain = from + 1;
            }
            return { "index" => plain, "rest" => true };
        }
        var start = from;
        while (start > 0 && supersetGroup(slots[start - 1]).equals(group)) {
            start = start - 1;
        }
        var end = from;
        while (end + 1 < slots.size() && supersetGroup(slots[end + 1]).equals(group)) {
            end = end + 1;
        }
        var ids = [] as Array<String>;
        var orders = [] as Array<Number>;
        var firsts = [] as Array<Number>;
        for (var n = start; n <= end; n++) {
            var item = slots[n];
            var itemId = item["exerciseId"] as String;
            if (memberIndex(ids, itemId) >= 0) {
                continue;
            }
            var order = 1000000 + ids.size();
            if (item["supersetOrder"] != null) {
                order = asInt(item["supersetOrder"]);
            }
            ids.add(itemId);
            orders.add(order);
            firsts.add(n);
        }
        sortMembers(ids, orders, firsts);
        var currentId = slot["exerciseId"] as String;
        var position = memberIndex(ids, currentId);
        var setIndex = slot["setIndex"] as Number;
        if (position < 0) {
            position = 0;
        }
        for (var later = position + 1; later < ids.size(); later++) {
            var partner = findSet(ids[later], setIndex, start, end);
            if (partner >= 0) {
                return { "index" => partner, "rest" => false };
            }
        }
        if (ids.size() > 0) {
            var following = findSet(ids[0], setIndex + 1, start, end);
            if (following >= 0) {
                return { "index" => following, "rest" => true };
            }
        }
        var after = end + 1;
        if (after >= slots.size()) {
            after = from;
        }
        return { "index" => after, "rest" => true };
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
        toneTimer.stop();
        tonesLeft = 0;
        restRemaining = 0;
        restPaused = false;
        restEndsAt = 0;
        persistRest();
        clearBackgroundRestAlert();
    }

    // Phone rest is an absolute end. A payload without restEndsAt leaves a
    // watch-started countdown alone. restCancelled stops it without a buzz.
    function applyPhoneRest(data as Dictionary) as Void {
        if (data["soundEnabled"] != null) {
            soundEnabled = data["soundEnabled"] == true;
        }
        if (data["restCancelled"] == true) {
            stopRest();
            return;
        }
        if (data["restPaused"] == true) {
            var left = asInt(data["restRemaining"]);
            restPaused = true;
            restRemaining = left;
            restEndsAt = 0;
            timer.stop();
            persistRest();
            clearBackgroundRestAlert();
            return;
        }
        if (data["restEndsAt"] == null) {
            return;
        }
        var ends = asInt(data["restEndsAt"]);
        var now = unixNow();
        if (ends <= now) {
            return;
        }
        restEndedOnItsOwn = false;
        restPaused = false;
        restEndsAt = ends;
        restRemaining = ends - now;
        timer.stop();
        timer.start(method(:tickRest), 1000, true);
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
        WatchUi.requestUpdate();
    }

    function cancelRest() as Void {
        if (restRemaining <= 0) {
            return;
        }
        var leaving = exitAfterRest;
        exitAfterRest = false;
        stopRest();
        if (leaving) {
            leaveNow();
            return;
        }
        WatchUi.requestUpdate();
    }

    function tickRest() as Void {
        // Countdown ticks only update the clock. Haptics fire on start,
        // pause, resume, adjust, cancel, and when the timer hits zero.
        syncRestClock(false);
    }

    // Remaining time is an absolute end timestamp so a dimmed screen,
    // a slow timer, or a relaunch still shows the real countdown.
    // A killed process cannot vibrate on its own. The system can own
    // an alert only through a temporal event, and that cannot be sooner
    // than BACKGROUND_REST_FLOOR seconds. Shorter rests stay on screen.
    function syncRestClock(fromDraw as Boolean) as Void {
        if (restPaused || restEndsAt <= 0) {
            return;
        }
        var left = restEndsAt - unixNow();
        if (left <= 0) {
            // onUpdate drops vibration. The one-second timer owns the cue.
            if (fromDraw) {
                restRemaining = 0;
                return;
            }
            restEndsAt = 0;
            restRemaining = 0;
            restPaused = false;
            timer.stop();
            restEndedOnItsOwn = true;
            persistRest();
            clearBackgroundRestAlert();
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

    // Registers a system-owned wake only when the real end is at least
    // five minutes away. A shorter rest returns false and must keep
    // running in this process. Returns false when the platform rejects
    // the time as well, including a second event inside five minutes.
    function armBackgroundRestAlert() as Boolean {
        if (restPaused || restEndsAt <= 0) {
            clearBackgroundRestAlert();
            return false;
        }
        var left = restEndsAt - unixNow();
        if (left < BACKGROUND_REST_FLOOR) {
            clearBackgroundRestAlert();
            return false;
        }
        try {
            Background.registerForTemporalEvent(new Time.Moment(restEndsAt));
            return true;
        } catch (ex) {
            return false;
        }
    }

    function clearBackgroundRestAlert() as Void {
        try {
            Background.deleteTemporalEvent();
        } catch (ex) {
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
        // The phone Connect IQ listener writes this into the journal.
        send("finishWorkout");
        cueSetDone();
        WatchUi.requestUpdate();
    }

    function playRestTones() as Void {
        if (soundEnabled == false) {
            return;
        }
        tonesLeft = 5;
        toneTimer.stop();
        toneTimer.start(method(:beepRest), 450, true);
        beepRest();
    }

    function beepRest() as Void {
        if (tonesLeft <= 0 || soundEnabled == false) {
            tonesLeft = 0;
            toneTimer.stop();
            return;
        }
        tonesLeft = tonesLeft - 1;
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_LOUD_BEEP);
        }
        if (tonesLeft <= 0) {
            toneTimer.stop();
        }
    }

    function requestHome() as Void {
        if (restRemaining > 0) {
            exitAfterRest = true;
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

    function indexForSlot(exerciseId as String, setIndex as Number) as Number {
        if (exerciseId.length() > 0) {
            for (var i = 0; i < slots.size(); i++) {
                var slot = slots[i];
                if ((slot["exerciseId"] as String).equals(exerciseId) && (slot["setIndex"] as Number) == setIndex) {
                    return i;
                }
            }
        }
        return firstOpen();
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
    var weight = asInt(raw["weight"]);
    if (raw["weightDisplay"] != null) {
        weight = asInt(raw["weightDisplay"]);
    }
    var slot = makeSlot(id, name, asInt(raw["setIndex"]), setCount, asInt(raw["reps"]), weight);
    slot["done"] = raw["done"] == true || raw["checked"] == true;
    if (raw["supersetGroupId"] instanceof String) {
        slot["supersetGroupId"] = raw["supersetGroupId"];
    }
    if (raw["supersetLabel"] instanceof String) {
        slot["supersetLabel"] = raw["supersetLabel"];
    }
    if (raw["supersetOrder"] != null) {
        slot["supersetOrder"] = asInt(raw["supersetOrder"]);
    }
    return slot;
}

function supersetGroup(slot as Dictionary) as String {
    if (slot["supersetGroupId"] instanceof String) {
        return slot["supersetGroupId"] as String;
    }
    return "";
}

function memberIndex(ids as Array<String>, exerciseId as String) as Number {
    for (var i = 0; i < ids.size(); i++) {
        if (ids[i].equals(exerciseId)) {
            return i;
        }
    }
    return -1;
}

function findSet(exerciseId as String, setIndex as Number, start as Number, end as Number) as Number {
    var session = getApp().session;
    for (var i = start; i <= end; i++) {
        var slot = session.slots[i];
        if ((slot["exerciseId"] as String).equals(exerciseId) && (slot["setIndex"] as Number) == setIndex) {
            return i;
        }
    }
    return -1;
}

function sortMembers(ids as Array<String>, orders as Array<Number>, firsts as Array<Number>) as Void {
    for (var i = 1; i < ids.size(); i++) {
        var id = ids[i];
        var order = orders[i];
        var first = firsts[i];
        var j = i - 1;
        while (j >= 0 && (orders[j] > order || (orders[j] == order && firsts[j] > first))) {
            ids[j + 1] = ids[j];
            orders[j + 1] = orders[j];
            firsts[j + 1] = firsts[j];
            j = j - 1;
        }
        ids[j + 1] = id;
        orders[j + 1] = order;
        firsts[j + 1] = first;
    }
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
        var text = value as String;
        // "8-12" is not a number. The working count is the top of the range.
        if (text.find("-") != null) {
            return maxIntIn(text);
        }
        var parsed = text.toNumber();
        if (parsed == null) {
            return maxIntIn(text);
        }
        if (parsed instanceof Float) {
            return (parsed as Float).toNumber();
        }
        if (parsed instanceof Long) {
            return (parsed as Long).toNumber();
        }
        if (parsed instanceof Number) {
            return parsed as Number;
        }
        return maxIntIn(text);
    }
    return 0;
}

function maxIntIn(text as String) as Number {
    var best = -1;
    var current = 0;
    var inNumber = false;
    var digits = "0123456789";
    for (var i = 0; i < text.length(); i += 1) {
        var ch = text.substring(i, i + 1);
        var at = digits.find(ch);
        if (at != null) {
            current = current * 10 + (at as Number);
            inNumber = true;
        } else if (inNumber) {
            if (current > best) {
                best = current;
            }
            current = 0;
            inNumber = false;
        }
    }
    if (inNumber && current > best) {
        best = current;
    }
    if (best < 0) {
        return 0;
    }
    return best;
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

// Ordinary taps stay silent. A finished set gets one short pulse.
// Rest done is several full-intensity pulses, a tone, and the backlight.
function cueStep() as Void {
}

function cueSetDone() as Void {
    if (Attention has :vibrate) {
        Attention.vibrate([new Attention.VibeProfile(20, 40)]);
    }
}

function cueUndo() as Void {
}

function cueRestDone() as Void {
    var session = getApp().session;
    if (Attention has :backlight) {
        Attention.backlight(true);
    }
    if (Attention has :vibrate) {
        Attention.vibrate([
            new Attention.VibeProfile(100, 400),
            new Attention.VibeProfile(0, 140),
            new Attention.VibeProfile(100, 400),
            new Attention.VibeProfile(0, 140),
            new Attention.VibeProfile(100, 400),
            new Attention.VibeProfile(0, 140),
            new Attention.VibeProfile(100, 500),
            new Attention.VibeProfile(0, 140),
            new Attention.VibeProfile(100, 500)
        ]);
    }
    if (session.soundEnabled) {
        session.playRestTones();
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
