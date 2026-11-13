import Foundation
import UserNotifications
import WatchKit

/// System-owned rest alert. The trigger is an absolute offset from the real
/// end time, so pause, resume, and length changes replace this same request.
enum RestAlertPlan {
    static let identifier = "liftbig.rest"

    /// Phone message that stops the looping rest tone. Garmin has no Stop control.
    static let stopMessageKind = "stopAlarm"

    static func showsStop(alarmRinging: Bool) -> Bool {
        alarmRinging
    }

    static func makeRequest(endsAt: Date, now: Date, soundEnabled: Bool) -> UNNotificationRequest? {
        let interval = endsAt.timeIntervalSince(now)
        guard interval > 0.5 else { return nil }
        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = "Time for the next set."
        content.interruptionLevel = .timeSensitive
        // watchOS cannot play a named file. The default tone is the sound it can own.
        content.sound = soundEnabled ? .default : nil
        content.userInfo = ["endsAt": endsAt.timeIntervalSince1970]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    /// The in-app haptic owns nothing by itself. Always-on and a foreground
    /// iPhone keep the scene active, and cancelling here is what used to
    /// leave only one tap. The pending alert stays so watchOS can present
    /// the banner and sound.
    static func cancelPendingWhenRestEnds(interfaceActive _: Bool) -> Bool {
        false
    }

    static func presentationOptions(soundEnabled: Bool) -> UNNotificationPresentationOptions {
        var options: UNNotificationPresentationOptions = [.banner, .list]
        if soundEnabled { options.insert(.sound) }
        return options
    }

    /// A few seconds. Notification, retry, and direction so it is not four identical taps.
    static let hapticPattern: [(WKHapticType, TimeInterval)] = [
        (.notification, 0),
        (.retry, 0.28),
        (.directionUp, 0.56),
        (.notification, 0.90),
        (.click, 1.15),
        (.directionDown, 1.40),
        (.retry, 1.70),
        (.notification, 2.05),
        (.directionUp, 2.35),
        (.notification, 2.70),
    ]

    static func playRestDoneHaptic() {
        let device = WKInterfaceDevice.current()
        for item in hapticPattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + item.1) {
                device.play(item.0)
            }
        }
    }

    static func submit(
        _ request: UNNotificationRequest,
        center: UNUserNotificationCenter = .current(),
        completion: @escaping (Error?) -> Void
    ) {
        center.add(request, withCompletionHandler: completion)
    }
}
