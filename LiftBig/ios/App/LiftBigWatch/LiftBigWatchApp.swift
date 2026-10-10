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
    @Published var restRemaining = 0
    private var timer: Timer?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let json = session.receivedApplicationContext["sessionJson"] as? String {
            apply(json)
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
            Text(
                model.payload.reason == "pro"
                    ? "LiftBig Pro unlocks the watch."
                    : "Open a workout on your iPhone."
            )
            .multilineTextAlignment(.center)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
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
