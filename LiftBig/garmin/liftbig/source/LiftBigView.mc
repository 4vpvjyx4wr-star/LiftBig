using Toybox.Application;
using Toybox.Communications;
using Toybox.Graphics;
using Toybox.Timer;
using Toybox.WatchUi;

class LiftBigView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var session = Application.Storage.getValue("session");
        if (session == null || session["locked"] == true) {
            dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, "Open LiftBig Pro\non your phone", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        var name = session["exerciseName"];
        var weight = session["targetWeightDisplay"] + " " + session["weightUnit"];
        var reps = session["targetReps"] + " reps";
        var setLine = "Set " + (session["currentSetIndex"] + 1) + " of " + session["setCount"];
        dc.drawText(dc.getWidth() / 2, 28, Graphics.FONT_MEDIUM, name, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, 62, Graphics.FONT_SMALL, weight, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, 88, Graphics.FONT_SMALL, reps, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, 114, Graphics.FONT_SMALL, setLine, Graphics.TEXT_JUSTIFY_CENTER);
        var rest = Application.Storage.getValue("restRemaining");
        if (rest != null && rest > 0) {
            dc.drawText(dc.getWidth() / 2, 146, Graphics.FONT_MEDIUM, "Rest " + rest, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class LiftBigDelegate extends WatchUi.BehaviorDelegate {
    var restTimer;

    function initialize() {
        BehaviorDelegate.initialize();
        restTimer = new Timer.Timer();
    }

    function onSelect() {
        completeSet();
        return true;
    }

    function onNextPage() {
        adjust(1, 2.5);
        return true;
    }

    function onPreviousPage() {
        adjust(-1, -2.5);
        return true;
    }

    function completeSet() {
        send("completeSet");
        var session = Application.Storage.getValue("session");
        var seconds = 60;
        if (session != null && session["restSeconds"] != null) {
            seconds = session["restSeconds"];
        }
        Application.Storage.setValue("restRemaining", seconds);
        restTimer.stop();
        restTimer.start(method(:tickRest), 1000, true);
        WatchUi.requestUpdate();
    }

    function tickRest() as Void {
        var left = Application.Storage.getValue("restRemaining");
        if (left == null) {
            return;
        }
        left = left - 1;
        Application.Storage.setValue("restRemaining", left);
        if (left <= 0) {
            restTimer.stop();
        }
        WatchUi.requestUpdate();
    }

    function adjust(repDelta, weightDelta) {
        var session = Application.Storage.getValue("session");
        if (session == null) {
            return;
        }
        var reps = session["targetReps"].toNumber();
        if (reps == null) {
            reps = 0;
        }
        reps = reps + repDelta;
        if (reps < 0) {
            reps = 0;
        }
        session["targetReps"] = reps.toString();
        var weight = session["targetWeightDisplay"].toFloat();
        if (weight == null) {
            weight = 0;
        }
        weight = weight + weightDelta;
        if (weight < 0) {
            weight = 0;
        }
        session["targetWeightDisplay"] = weight.toString();
        Application.Storage.setValue("session", session);
        send("adjustSet");
        WatchUi.requestUpdate();
    }

    function send(kind) {
        var session = Application.Storage.getValue("session");
        if (session == null) {
            return;
        }
        var message = {
            "version" => 1,
            "kind" => kind,
            "dateKey" => session["dateKey"],
            "exerciseId" => session["exerciseId"],
            "setIndex" => session["currentSetIndex"],
            "reps" => session["targetReps"],
            "weightDisplay" => session["targetWeightDisplay"],
            "weightUnit" => session["weightUnit"]
        };
        Communications.transmit(message, null, new CommListener());
    }
}

class CommListener extends Communications.ConnectionListener {
    function initialize() {
        ConnectionListener.initialize();
    }

    function onComplete() {
    }

    function onError() {
    }
}
