// The iPhone Watch app reports an unverified source because this companion is
// development-signed. watchOS hides Developer Mode until Xcode has offered the
// watch a development app. Installing from the iPhone Watch app alone does not
// reveal the toggle.
//
// 1. On the iPhone: Settings > Privacy & Security > Developer Mode, then restart.
// 2. Connect the iPhone to the Mac, unlock the watch, then Xcode > Window >
//    Devices and Simulators, and select the paired watch.
// 3. On the watch, Developer Mode then appears at the bottom of Privacy &
//    Security. Turn it on and let the watch restart.
// 4. Run the LiftBigWatch scheme on that watch once from Xcode. After that, the
//    iPhone Watch app can install this development build.

import SwiftUI
import WatchConnectivity
import WatchKit

struct WatchPayload: Decodable {
    var version: Int
    var locked: Bool
    var reason: String?
    var exerciseName: String?
    var targetWeightDisplay: String?
    var targetReps: String?
    var setCount: Int?
    var currentSetIndex: Int?
    var restSeconds: Int?
    var weightUnit: String?
    var dateKey: String?
    var exerciseId: String?
}

final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var payload = WatchPayload(version: 1, locked: true, reason: "idle")
    @Published var phoneLink = "Connecting to iPhone…"
    @Published var restRemaining = 0
    private var timer: Timer?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            phoneLink = "Watch link unavailable"
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.noteLink(session, activationState: activationState, error: error)
        }
        if let json = session.receivedApplicationContext["sessionJson"] as? String {
            apply(json)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.noteLink(session, activationState: session.activationState, error: nil)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let json = applicationContext["sessionJson"] as? String {
            apply(json)
        }
    }

    func completeSet() {
        send(kind: "completeSet")
        startRest()
    }

    func adjust(repsDelta: Int, weightDelta: Double) {
        guard var reps = Int(payload.targetReps ?? "0") else { return }
        reps = max(0, reps + repsDelta)
        let current = Double(payload.targetWeightDisplay ?? "0") ?? 0
        let next = max(0, current + weightDelta)
        payload.targetReps = String(reps)
        payload.targetWeightDisplay = next.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(next)) : String(next)
        send(kind: "adjustSet")
    }

    private func startRest() {
        restRemaining = payload.restSeconds ?? 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.restRemaining <= 1 {
                self.restRemaining = 0
                timer.invalidate()
                WKInterfaceDevice.current().play(.notification)
            } else {
                self.restRemaining -= 1
            }
        }
    }

    private func send(kind: String) {
        let object: [String: Any] = [
            "version": 1,
            "kind": kind,
            "dateKey": payload.dateKey ?? "",
            "exerciseId": payload.exerciseId ?? "",
            "setIndex": payload.currentSetIndex ?? 0,
            "reps": payload.targetReps ?? "",
            "weightDisplay": payload.targetWeightDisplay ?? "",
            "weightUnit": payload.weightUnit ?? "lb",
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let json = String(data: data, encoding: .utf8) else { return }
        let body = ["messageJson": json]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(body, replyHandler: nil, errorHandler: nil)
        } else {
            WCSession.default.transferUserInfo(body)
        }
    }

    private func noteLink(_ session: WCSession, activationState: WCSessionActivationState, error: Error?) {
        if error != nil || activationState != .activated {
            phoneLink = "iPhone link unavailable"
        } else if session.isReachable {
            phoneLink = "iPhone connected"
        } else {
            phoneLink = "Paired with iPhone"
        }
    }

    private func apply(_ json: String) {
        guard let data = json.data(using: .utf8),
              let next = try? JSONDecoder().decode(WatchPayload.self, from: data) else { return }
        DispatchQueue.main.async { self.payload = next }
    }
}

@main
struct LiftBigWatchApp: App {
    @StateObject private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchSessionView(model: model)
        }
    }
}

struct WatchSessionView: View {
    @ObservedObject var model: WatchModel

    var body: some View {
        if model.payload.locked {
            VStack(spacing: 8) {
                Text(model.phoneLink)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                Text(
                    model.payload.reason == "pro"
                        ? "LiftBig Pro unlocks the watch."
                        : "Open a workout on your iPhone."
                )
                .multilineTextAlignment(.center)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.phoneLink)
                        .font(.footnote)
                    Text(model.payload.exerciseName ?? "Exercise")
                        .font(.headline)
                    Text("Goal \(model.payload.targetWeightDisplay ?? "—") \(model.payload.weightUnit ?? "lb")")
                    Text("\(model.payload.targetReps ?? "—") reps · set \((model.payload.currentSetIndex ?? 0) + 1) of \(model.payload.setCount ?? 1)")
                    if model.restRemaining > 0 {
                        Text("Rest \(model.restRemaining)s")
                            .font(.title3)
                    }
                    Button("Set done") { model.completeSet() }
                    HStack {
                        Button("-") { model.adjust(repsDelta: -1, weightDelta: -2.5) }
                        Button("+") { model.adjust(repsDelta: 1, weightDelta: 2.5) }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
