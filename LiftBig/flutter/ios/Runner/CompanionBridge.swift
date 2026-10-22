import Flutter
import Foundation
import WatchConnectivity

/// Phone side of the Apple Watch companion.
///
/// `publishSession` writes `sessionJson` into the WatchConnectivity application
/// context. Messages from the watch are forwarded to Dart as `companionMessage`.
final class CompanionBridge: NSObject, WCSessionDelegate {
    static let shared = CompanionBridge()

    private var channel: FlutterMethodChannel?
    private var watchActivated = false
    private var pendingSession: String?

    private override init() {
        super.init()
    }

    /// Activates the watch session as soon as the phone process launches.
    func start() {
        activateWatch()
    }

    func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "liftbig/companion", binaryMessenger: messenger)
        self.channel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(nil)
                return
            }
            switch call.method {
            case "publishSession":
                let json = (call.arguments as? [String: Any])?["sessionJson"] as? String
                    ?? "{\"version\":1,\"locked\":true,\"reason\":\"idle\"}"
                self.publish(json)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        activateWatch()
    }

    private func publish(_ json: String) {
        pendingSession = json
        sendWatch(json)
    }

    private func deliver(messageJson: String) {
        let channel = channel
        DispatchQueue.main.async {
            channel?.invokeMethod("companionMessage", arguments: ["messageJson": messageJson])
        }
    }

    // MARK: Apple Watch

    private func activateWatch() {
        guard WCSession.isSupported() else { return }
        if WCSession.default.delegate == nil {
            WCSession.default.delegate = self
        }
        if !watchActivated {
            watchActivated = true
            WCSession.default.activate()
        }
    }

    private func sendWatch(_ json: String) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext(["sessionJson": json])
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let pendingSession {
            sendWatch(pendingSession)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        forwardWatch(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        forwardWatch(userInfo)
    }

    private func forwardWatch(_ payload: [String: Any]) {
        guard let json = payload["messageJson"] as? String else { return }
        deliver(messageJson: json)
    }
}
