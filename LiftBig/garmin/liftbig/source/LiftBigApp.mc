using Toybox.Application;
using Toybox.Communications;
using Toybox.WatchUi;

class LiftBigApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new LiftBigDelegate(), new LiftBigView()];
    }

    function onStart(state) {
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
    }

    function onPhoneMessage(message) as Void {
        if (message != null && message.data != null) {
            Application.Storage.setValue("session", message.data);
            WatchUi.requestUpdate();
        }
    }
}
