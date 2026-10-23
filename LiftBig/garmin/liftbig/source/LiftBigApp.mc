import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class LiftBigApp extends Application.AppBase {
    var session as Session = new Session();

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        if (Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(method(:onPhone));
        }
        session.restoreRest();
        session.ensureActivity();
        System.println("LiftBig ready on Venu 3: " + session.exerciseName());
    }

    function onStop(state as Dictionary?) as Void {
        session.persistRest();
    }

    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        WatchUi.requestUpdate();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new LiftBigView(), new LiftBigDelegate()];
    }

    function onPhone(msg as Communications.PhoneAppMessage) as Void {
        if (msg.data instanceof Dictionary) {
            session.applyPhone(msg.data as Dictionary);
            WatchUi.requestUpdate();
        }
    }
}

function getApp() as LiftBigApp {
    return Application.getApp() as LiftBigApp;
}
