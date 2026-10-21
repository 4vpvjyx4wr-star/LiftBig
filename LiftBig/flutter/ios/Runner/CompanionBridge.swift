import ConnectIQ
import Flutter
import Foundation
import WatchConnectivity

/// Phone side of the Apple Watch and Garmin companions.
///
/// `publishSession` fans the same `sessionJson` out to both. Apple Watch reads
/// `sessionJson` from the application context. Garmin Connect IQ receives the
/// decoded dictionary, which is what `onPhoneMessage` stores. Watch messages
/// from either side are forwarded to Dart as `companionMessage`.
final class CompanionBridge: NSObject, WCSessionDelegate, IQAppMessageDelegate, IQDeviceEventDelegate, IQUIOverrideDelegate {
    static let shared = CompanionBridge()

    /// Connect IQ app id from `LiftBig/garmin/liftbig/manifest.xml`.
    private static let garminAppId = "c3a1e7b2-4d58-4f0a-9b6e-2f7a1d8c0e44"
    private static let urlScheme = "liftbig"
    private static let devicesKey = "liftbig.garmin.devices"

    private var channel: FlutterMethodChannel?
    private var watchActivated = false
    private var garminActivated = false
    private var promptedForDevices = false
    private var pendingSession: String?
    private var savedDevices: [SavedGarminDevice] = []

    private override init() {
        super.init()
        savedDevices = Self.loadDevices()
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
        activateGarmin()
    }

    /// Garmin Connect returns the chosen watches by opening this URL scheme.
    func handleOpen(url: URL) -> Bool {
        guard url.scheme == Self.urlScheme else { return false }
        let parsed = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url) ?? []
        let devices = parsed.compactMap { $0 as? IQDevice }
        guard !devices.isEmpty else { return false }
        remember(devices)
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

    // MARK: Garmin

    private func activateGarmin() {
        guard !garminActivated else { return }
        garminActivated = true
        ConnectIQ.sharedInstance().initialize(withUrlScheme: Self.urlScheme, uiOverrideDelegate: self)
        for device in iqDevices() {
            let app = iqApp(on: device)
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
            ConnectIQ.sharedInstance().register(forAppMessages: app, delegate: self)
        }
    }

    private func sendGarmin(_ json: String) {
        guard garminActivated else { return }
        guard let message = garminPayload(json) else { return }
        let devices = iqDevices()
        if devices.isEmpty {
            if !promptedForDevices {
                promptedForDevices = true
                ConnectIQ.sharedInstance().showDeviceSelection()
            }
            return
        }
        for device in devices {
            let app = iqApp(on: device)
            ConnectIQ.sharedInstance().sendMessage(
                message,
                to: app,
                progress: { _, _ in },
                completion: { _ in }
            )
        }
    }

    func receivedMessage(_ message: Any!, from app: IQApp!) {
        guard let message, let json = Self.jsonString(message) else { return }
        deliver(messageJson: json)
    }

    func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
        _ = device
        _ = status
    }

    func deviceCharacteristicsDiscovered(_ device: IQDevice!) {
        guard let pendingSession else { return }
        sendGarmin(pendingSession)
    }

    func needsToInstallConnectMobile() {
        // Garmin Connect is not installed. Leave the session on the phone.
    }

    private func iqApp(on device: IQDevice) -> IQApp {
        let uuid = UUID(uuidString: Self.garminAppId)!
        return IQApp(uuid: uuid, store: uuid, device: device)
    }

    private func iqDevices() -> [IQDevice] {
        savedDevices.compactMap { saved -> IQDevice? in
            guard let uuid = UUID(uuidString: saved.uuid) else { return nil }
            if let partNumber = saved.partNumber, !partNumber.isEmpty {
                return IQDevice(
                    id: uuid,
                    modelName: saved.modelName,
                    friendlyName: saved.friendlyName,
                    partNumber: partNumber
                )
            }
            return IQDevice(id: uuid, modelName: saved.modelName, friendlyName: saved.friendlyName)
        }
    }

    private func remember(_ devices: [IQDevice]) {
        savedDevices = devices.map {
            SavedGarminDevice(
                uuid: $0.uuid.uuidString,
                modelName: $0.modelName ?? "",
                friendlyName: $0.friendlyName ?? "",
                partNumber: $0.partNumber
            )
        }
        if let data = try? JSONEncoder().encode(savedDevices) {
            UserDefaults.standard.set(data, forKey: Self.devicesKey)
        }
        for device in iqDevices() {
            let app = iqApp(on: device)
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: self)
            ConnectIQ.sharedInstance().register(forAppMessages: app, delegate: self)
        }
    }

    private static func loadDevices() -> [SavedGarminDevice] {
        guard let data = UserDefaults.standard.data(forKey: devicesKey),
              let devices = try? JSONDecoder().decode([SavedGarminDevice].self, from: data) else {
            return []
        }
        return devices
    }

    /// The watch app stores `message.data` as a dictionary, so the phone sends
    /// the decoded session rather than the JSON string.
    private func garminPayload(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object
    }

    private static func jsonString(_ message: Any) -> String? {
        let payload: Any
        if let list = message as? [Any], list.count == 1, let first = list.first {
            payload = first
        } else {
            payload = message
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
}

private struct SavedGarminDevice: Codable {
    var uuid: String
    var modelName: String
    var friendlyName: String
    var partNumber: String?
}
