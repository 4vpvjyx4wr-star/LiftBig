import ConnectIQ
import Flutter
import Foundation
import UIKit
import WatchConnectivity

/// Phone side of the Apple Watch companion and the Garmin Connect IQ app.
///
/// `publishSession` writes `sessionJson` into the WatchConnectivity application
/// context and sends the same dictionary the Android bridge sends to Connect IQ.
/// Messages from either watch are forwarded to Dart as `companionMessage`.
/// Garmin Connect has to be installed. If it is not, the Garmin path does nothing.
final class CompanionBridge: NSObject, WCSessionDelegate, IQUIOverrideDelegate, IQDeviceEventDelegate, IQAppMessageDelegate {
    static let shared = CompanionBridge()

    /// App id from `LiftBig/garmin/liftbig/manifest.xml`.
    private static let garminAppId = UUID(uuidString: "C3A1E7B2-4D58-4F0A-9B6E-2F7A1D8C0E44")!
    private static let urlScheme = "liftbig"
    private static let devicesKey = "liftbig.garmin.devices"

    private var channel: FlutterMethodChannel?
    private var watchActivated = false
    private var pendingSession: String?
    private var garminReady = false
    private var askedForDevices = false
    private var devices: [IQDevice] = []

    private override init() {
        super.init()
    }

    /// Activates the watch session as soon as the phone process launches.
    func start() {
        activateWatch()
        startGarmin()
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
            case "startWorkout":
                let json = (call.arguments as? [String: Any])?["sessionJson"] as? String
                    ?? "{\"version\":1,\"locked\":true,\"reason\":\"idle\"}"
                self.publish(json)
                self.launchWatch(json)
                self.openGarminApp()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        activateWatch()
        startGarmin()
    }

    /// Garmin Connect returns the chosen watches on the `liftbig` URL scheme.
    func open(url: URL) -> Bool {
        guard url.scheme?.caseInsensitiveCompare(Self.urlScheme) == .orderedSame else { return false }
        startGarmin()
        guard garminReady, let iq = connectIQ(),
              let parsed = iq.parseDeviceSelectionResponse(from: url) as? [IQDevice],
              !parsed.isEmpty else {
            return false
        }
        devices = parsed
        archive(parsed)
        listen(parsed)
        if let pendingSession {
            sendGarmin(pendingSession)
        }
        return true
    }

    private func publish(_ json: String) {
        pendingSession = json
        sendWatch(json)
        sendGarmin(json)
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

    /// Wakes the watch app when it can be reached. A sleeping watch must not throw.
    private func launchWatch(_ json: String) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["sessionJson": json, "command": "start"], replyHandler: nil) { _ in }
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

    // MARK: Garmin Connect IQ

    private func garminConnectInstalled() -> Bool {
        guard let url = URL(string: "gcm-ciq://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func connectIQ() -> ConnectIQ? {
        ConnectIQ.sharedInstance()
    }

    private func startGarmin() {
        guard garminConnectInstalled(), let iq = connectIQ() else { return }
        if !garminReady {
            garminReady = true
            iq.initialize(withUrlScheme: Self.urlScheme, uiOverrideDelegate: self)
            let restored = restoreDevices()
            if !restored.isEmpty {
                devices = restored
                listen(restored)
            }
        }
    }

    /// Garmin Connect is missing, or the user has not shared a watch. Do nothing.
    func needsToInstallConnectMobile() {}

    private func sendGarmin(_ json: String) {
        guard garminConnectInstalled() else { return }
        startGarmin()
        guard garminReady, let payload = garminPayload(from: json) else { return }
        if devices.isEmpty {
            if !askedForDevices, let iq = connectIQ() {
                askedForDevices = true
                iq.showDeviceSelection()
            }
            return
        }
        guard let iq = connectIQ() else { return }
        for device in devices {
            guard let app = garminApp(on: device) else { continue }
            iq.sendMessage(payload, to: app, progress: { _, _ in }, completion: { _ in })
        }
    }

    private func openGarminApp() {
        guard garminConnectInstalled() else { return }
        startGarmin()
        guard garminReady, let iq = connectIQ() else { return }
        for device in devices {
            guard let app = garminApp(on: device) else { continue }
            iq.openAppRequest(app) { _ in }
        }
    }

    private func listen(_ devices: [IQDevice]) {
        guard let iq = connectIQ() else { return }
        for device in devices {
            iq.register(forDeviceEvents: device, delegate: self)
            if let app = garminApp(on: device) {
                iq.register(forAppMessages: app, delegate: self)
            }
        }
    }

    private func garminApp(on device: IQDevice) -> IQApp? {
        IQApp(uuid: Self.garminAppId, store: Self.garminAppId, device: device)
    }

    func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
        guard status == .connected, let pendingSession else { return }
        sendGarmin(pendingSession)
    }

    func deviceCharacteristicsDiscovered(_ device: IQDevice) {
        guard let pendingSession else { return }
        sendGarmin(pendingSession)
    }

    func receivedMessage(_ message: Any, from app: IQApp) {
        guard let json = garminMessageJson(message) else { return }
        deliver(messageJson: json)
    }

    /// Same shape Android sends: a dictionary, with whole numbers as integers.
    private func garminPayload(from json: String) -> Any? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        return jsonCompatible(object)
    }

    private func jsonCompatible(_ value: Any) -> Any {
        switch value {
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue
            }
            let double = number.doubleValue
            if double.rounded() == double, double <= Double(Int.max), double >= Double(Int.min) {
                return Int(double)
            }
            return double
        case let array as [Any]:
            return array.map { jsonCompatible($0) }
        case let dict as [String: Any]:
            var mapped: [String: Any] = [:]
            for (key, item) in dict {
                if item is NSNull { continue }
                mapped[key] = jsonCompatible(item)
            }
            return mapped
        default:
            return value
        }
    }

    /// Android wraps one dictionary in a list. The watch stored a dictionary.
    private func garminMessageJson(_ message: Any) -> String? {
        let payload: Any
        if let list = message as? [Any] {
            if list.isEmpty { return nil }
            payload = list.count == 1 ? (list[0]) : list
        } else {
            payload = message
        }
        if let text = payload as? String { return text }
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return nil }
        return json
    }

    private func archive(_ devices: [IQDevice]) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: devices, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: Self.devicesKey)
        } catch {
            // The watches stay in memory for this launch.
        }
    }

    private func restoreDevices() -> [IQDevice] {
        guard let data = UserDefaults.standard.data(forKey: Self.devicesKey) else { return [] }
        do {
            if let devices = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSDictionary.self, NSString.self, NSNumber.self, NSUUID.self, IQDevice.self],
                from: data
            ) as? [IQDevice] {
                return devices
            }
        } catch {
            return []
        }
        return []
    }
}
