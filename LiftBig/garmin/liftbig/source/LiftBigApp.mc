import Toybox.Application;
import Toybox.Background;
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
        session.clearBackgroundRestAlert();
        session.restoreRest();
        session.ensureActivity();
        System.println("LiftBig ready on Venu 3: " + session.exerciseName());
    }

    function onStop(state as Dictionary?) as Void {
        session.persistRest();
        // The in-app beep is the exact alert. This arms the system dialog
        // only if the process is actually stopping with at least five
        // minutes left. A shorter rest cannot be handed to the system.
        session.armBackgroundRestAlert();
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new LiftBigServiceDelegate()];
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

// Runs only after the app process has stopped. Connect IQ will not
// start this sooner than five minutes, and it cannot play a tone.
(:background)
class LiftBigServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        Background.requestApplicationWake("Rest complete");
        Background.exit(null);
    }
}
