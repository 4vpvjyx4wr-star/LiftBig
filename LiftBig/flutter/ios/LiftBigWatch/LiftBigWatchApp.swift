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
import UserNotifications
import WatchConnectivity
import WatchKit

struct WatchSlot: Decodable {
    var exerciseId: String
    var exerciseName: String
    var setIndex: Int
    var setCount: Int
    var reps: String
    var weightDisplay: String
    var checked: Bool
}

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
    var lineup: [WatchSlot]?
}

final class WatchModel: NSObject, ObservableObject, WCSessionDelegate, UNUserNotificationCenterDelegate {
    @Published var payload = WatchPayload(version: 1, locked: true, reason: "idle")
    @Published var phoneLink = "Connecting to iPhone…"
    @Published var restRemaining = 0
    @Published var restPaused = false
    @Published var restPreset = 60
    @Published var viewIndex = 0
    @Published var revision = 0
    private var timer: Timer?
    private var restEndsAt: Date?
    private var restTouched = false
    private var edits: [String: (reps: String, weight: String)] = [:]
    private var doneOverrides: [String: Bool] = [:]
    let runtime = WorkoutRuntime()
    private static let restAlertId = "liftbig.rest"
    private static let restEndsKey = "lb.restEnds"
    private static let restPausedKey = "lb.restPaused"

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            phoneLink = "Watch link unavailable"
        }
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        restoreRest()
    }

    func ensureRuntime() {
        guard !payload.locked else { return }
        runtime.startIfNeeded()
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

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let json = message["sessionJson"] as? String {
            apply(json)
        }
    }

    func isDone(_ slot: WatchSlot) -> Bool {
        if let override = doneOverrides[slotKey(slot)] { return override }
        return slot.checked
    }

    func toggleSetDone() {
        guard let slot = viewed else { return }
        if isDone(slot) {
            undoSet()
        } else {
            completeSet()
        }
    }

    func completeSet() {
        guard let slot = viewed else { return }
        doneOverrides[slotKey(slot)] = true
        WKInterfaceDevice.current().play(.success)
        send(kind: "completeSet")
        startRest()
        if viewIndex + 1 < lineup.count {
            viewIndex += 1
        }
        revision += 1
    }

    func undoSet() {
        guard let slot = viewed else { return }
        doneOverrides[slotKey(slot)] = false
        WKInterfaceDevice.current().play(.retry)
        send(kind: "undoSet")
        revision += 1
    }

    func pauseRest() {
        guard restRemaining > 0, !restPaused else { return }
        syncRestFromClock(hapticStep: false)
        guard restRemaining > 0 else { return }
        restPaused = true
        restEndsAt = nil
        timer?.invalidate()
        timer = nil
        persistRest()
        cancelRestAlert()
        WKInterfaceDevice.current().play(.stop)
    }

    func resumeRest() {
        guard restRemaining > 0, restPaused else { return }
        restPaused = false
        restEndsAt = Date().addingTimeInterval(TimeInterval(restRemaining))
        persistRest()
        scheduleRestAlert()
        WKInterfaceDevice.current().play(.start)
        armRestTimer()
    }

    func cancelRest() {
        guard restRemaining > 0 else { return }
        timer?.invalidate()
        timer = nil
        restRemaining = 0
        restPaused = false
        restEndsAt = nil
        persistRest()
        cancelRestAlert()
        WKInterfaceDevice.current().play(.directionDown)
    }

    func goHome() {
        WKInterfaceDevice.current().play(.click)
        if restRemaining > 0, !restPaused {
            syncRestFromClock(hapticStep: false)
            if let restEndsAt, restEndsAt.timeIntervalSinceNow > 0 {
                scheduleRestAlert()
            }
        } else {
            cancelRestAlert()
        }
        persistRest()
        runtime.leaveToWatchFace()
    }

    func finishWorkout() {
        guard !payload.locked, payload.dateKey != nil else { return }
        for slot in lineup {
            if isDone(slot) {
                queue(slot: slot, kind: "completeSet")
            } else if slot.checked || doneOverrides[slotKey(slot)] == false {
                queue(slot: slot, kind: "undoSet")
            }
        }
        queueFinish()
        WKInterfaceDevice.current().play(.success)
    }

    func move(by delta: Int) {
        let count = lineup.count
        guard count > 0 else { return }
        let next = min(max(viewIndex + delta, 0), count - 1)
        guard next != viewIndex else { return }
        viewIndex = next
        WKInterfaceDevice.current().play(.click)
    }

    func jumpToOpenSet() {
        let open = openIndex
        guard open != viewIndex else { return }
        viewIndex = open
        WKInterfaceDevice.current().play(.click)
    }

    func adjustRest(by delta: Int) {
        let next = min(300, max(5, restPreset + delta))
        guard next != restPreset else { return }
        let change = next - restPreset
        restPreset = next
        restTouched = true
        if restRemaining > 0 {
            if restPaused {
                restRemaining = min(300, max(0, restRemaining + change))
            } else if let restEndsAt {
                let shifted = restEndsAt.addingTimeInterval(TimeInterval(change))
                let capped = min(shifted, Date().addingTimeInterval(300))
                self.restEndsAt = capped
                restRemaining = max(0, Int(ceil(capped.timeIntervalSinceNow)))
                if restRemaining == 0 {
                    finishRestAlert()
                } else {
                    scheduleRestAlert()
                }
            }
            persistRest()
        }
        WKInterfaceDevice.current().play(.click)
        send(kind: "setRest", restSeconds: next)
    }

    func adjustWeight(by delta: Double) {
        guard let slot = viewed else { return }
        let current = parseNumber(displayWeight())
        let next = max(0, current + delta)
        edits[slotKey(slot)] = (reps: displayReps(), weight: formatNumber(next))
        revision += 1
        WKInterfaceDevice.current().play(.click)
        send(kind: "adjustSet")
    }

    func adjustReps(by delta: Int) {
        guard let slot = viewed else { return }
        let reps = max(0, parseWhole(displayReps()) + delta)
        edits[slotKey(slot)] = (reps: String(reps), weight: displayWeight())
        revision += 1
        WKInterfaceDevice.current().play(.click)
        send(kind: "adjustSet")
    }

    var weightStep: Double {
        payload.weightUnit == "kg" ? 2.5 : 5
    }

    private func parseWhole(_ raw: String?) -> Int {
        let text = raw ?? ""
        let digits = text.split(whereSeparator: { !$0.isNumber }).first.map(String.init) ?? ""
        return Int(digits) ?? 0
    }

    private func parseNumber(_ raw: String?) -> Double {
        let text = (raw ?? "").replacingOccurrences(of: ",", with: ".")
        if let value = Double(text) { return value }
        let digits = text.split(whereSeparator: { !($0.isNumber || $0 == ".") }).first.map(String.init) ?? ""
        return Double(digits) ?? 0
    }

    private func formatNumber(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    func clock(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        return String(format: "%d:%02d", safe / 60, safe % 60)
    }

    private func startRest() {
        restPaused = false
        restRemaining = restPreset
        restEndsAt = Date().addingTimeInterval(TimeInterval(restPreset))
        persistRest()
        scheduleRestAlert()
        armRestTimer()
    }

    private func armRestTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.syncRestFromClock(hapticStep: true)
        }
    }

    func syncRestFromClock(hapticStep: Bool) {
        guard let restEndsAt, !restPaused else { return }
        let left = max(0, Int(ceil(restEndsAt.timeIntervalSinceNow)))
        if left <= 0 {
            finishRestAlert()
            return
        }
        if left != restRemaining {
            restRemaining = left
            if hapticStep {
                WKInterfaceDevice.current().play(.click)
            }
        }
    }

    private func finishRestAlert() {
        restRemaining = 0
        restPaused = false
        restEndsAt = nil
        timer?.invalidate()
        timer = nil
        persistRest()
        cancelRestAlert()
        WKInterfaceDevice.current().play(.notification)
    }

    private func persistRest() {
        if restPaused, restRemaining > 0 {
            UserDefaults.standard.set(restRemaining, forKey: Self.restPausedKey)
            UserDefaults.standard.removeObject(forKey: Self.restEndsKey)
            return
        }
        UserDefaults.standard.removeObject(forKey: Self.restPausedKey)
        if let restEndsAt {
            UserDefaults.standard.set(restEndsAt.timeIntervalSince1970, forKey: Self.restEndsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.restEndsKey)
        }
    }

    private func restoreRest() {
        let paused = UserDefaults.standard.integer(forKey: Self.restPausedKey)
        if paused > 0 {
            restPaused = true
            restRemaining = paused
            restEndsAt = nil
            return
        }
        let ends = UserDefaults.standard.double(forKey: Self.restEndsKey)
        guard ends > 0 else { return }
        let date = Date(timeIntervalSince1970: ends)
        let left = Int(ceil(date.timeIntervalSinceNow))
        if left <= 0 {
            UserDefaults.standard.removeObject(forKey: Self.restEndsKey)
            WKInterfaceDevice.current().play(.notification)
            return
        }
        restEndsAt = date
        restRemaining = left
        restPaused = false
        scheduleRestAlert()
        armRestTimer()
    }

    private func scheduleRestAlert() {
        guard let restEndsAt else { return }
        let interval = restEndsAt.timeIntervalSinceNow
        guard interval > 0.5 else { return }
        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = "Time for the next set."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.restAlertId, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.restAlertId])
        center.add(request)
    }

    private func cancelRestAlert() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.restAlertId])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.identifier == Self.restAlertId {
            syncRestFromClock(hapticStep: false)
            return []
        }
        return [.banner, .sound]
    }

    var lineup: [WatchSlot] { payload.lineup ?? [] }

    var openIndex: Int {
        let slots = lineup
        if let index = slots.firstIndex(where: { !$0.checked }) { return index }
        return slots.isEmpty ? 0 : slots.count - 1
    }

    var viewed: WatchSlot? {
        let slots = lineup
        guard !slots.isEmpty else { return nil }
        return slots[min(max(viewIndex, 0), slots.count - 1)]
    }

    var upcomingName: String? {
        let slots = lineup
        let next = viewIndex + 1
        guard slots.indices.contains(next) else { return nil }
        if slots[next].exerciseId == viewed?.exerciseId { return nil }
        return slots[next].exerciseName
    }

    func displayReps() -> String {
        if let slot = viewed, let edit = edits[slotKey(slot)] { return edit.reps }
        return viewed?.reps ?? payload.targetReps ?? "0"
    }

    func displayWeight() -> String {
        if let slot = viewed, let edit = edits[slotKey(slot)] { return edit.weight }
        return viewed?.weightDisplay ?? payload.targetWeightDisplay ?? "0"
    }

    func restLabel(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        let minutes = safe / 60
        let remainder = safe % 60
        if minutes == 0 { return safe == 1 ? "1 second" : "\(safe) seconds" }
        let minuteLabel = minutes == 1 ? "1 minute" : "\(minutes) minutes"
        if remainder == 0 { return minuteLabel }
        let secondLabel = remainder == 1 ? "1 second" : "\(remainder) seconds"
        return "\(minuteLabel) \(secondLabel)"
    }

    private func slotKey(_ slot: WatchSlot) -> String {
        "\(slot.exerciseId)#\(slot.setIndex)"
    }

    private func send(kind: String, restSeconds: Int? = nil) {
        let slot = viewed
        let object: [String: Any] = [
            "version": 1,
            "kind": kind,
            "dateKey": payload.dateKey ?? "",
            "exerciseId": slot?.exerciseId ?? payload.exerciseId ?? "",
            "setIndex": slot?.setIndex ?? payload.currentSetIndex ?? 0,
            "reps": displayReps(),
            "weightDisplay": displayWeight(),
            "weightUnit": payload.weightUnit ?? "lb",
            "restSeconds": restSeconds ?? restPreset,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let json = String(data: data, encoding: .utf8) else { return }
        let body = ["messageJson": json]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(body, replyHandler: nil) { _ in
                WCSession.default.transferUserInfo(body)
            }
        } else {
            WCSession.default.transferUserInfo(body)
        }
    }

    private func queue(slot: WatchSlot, kind: String) {
        let reps: String
        let weight: String
        if let edit = edits[slotKey(slot)] {
            reps = edit.reps
            weight = edit.weight
        } else {
            reps = slot.reps
            weight = slot.weightDisplay
        }
        let object: [String: Any] = [
            "version": 1,
            "kind": kind,
            "dateKey": payload.dateKey ?? "",
            "exerciseId": slot.exerciseId,
            "setIndex": slot.setIndex,
            "reps": reps,
            "weightDisplay": weight,
            "weightUnit": payload.weightUnit ?? "lb",
            "restSeconds": restPreset,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let json = String(data: data, encoding: .utf8) else { return }
        WCSession.default.transferUserInfo(["messageJson": json])
    }

    private func queueFinish() {
        let object: [String: Any] = [
            "version": 1,
            "kind": "finishWorkout",
            "dateKey": payload.dateKey ?? "",
            "exerciseId": viewed?.exerciseId ?? payload.exerciseId ?? "",
            "setIndex": viewed?.setIndex ?? payload.currentSetIndex ?? 0,
            "reps": displayReps(),
            "weightDisplay": displayWeight(),
            "weightUnit": payload.weightUnit ?? "lb",
            "restSeconds": restPreset,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object),
              let json = String(data: data, encoding: .utf8) else { return }
        WCSession.default.transferUserInfo(["messageJson": json])
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
        DispatchQueue.main.async {
            let dateChanged = next.dateKey != self.payload.dateKey
            self.payload = next
            if dateChanged { self.restTouched = false }
            if !self.restTouched {
                let incoming = min(300, max(5, next.restSeconds ?? 60))
                self.restPreset = incoming
            }
            self.edits = [:]
            self.doneOverrides = [:]
            let open = self.openIndex
            if self.viewIndex >= self.lineup.count || self.lineup.isEmpty {
                self.viewIndex = open
            }
            if !next.locked {
                self.ensureRuntime()
            } else {
                self.runtime.stopKeepingAwake()
            }
        }
    }
}

@main
struct LiftBigWatchApp: App {
    @StateObject private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchSessionView(model: model)
                .onOpenURL { _ in }
                .onAppear { model.ensureRuntime() }
        }
    }
}

struct WatchSessionView: View {
    @ObservedObject var model: WatchModel
    @Environment(\.scenePhase) private var scenePhase

    private var setIsDone: Bool {
        guard let slot = model.viewed else { return false }
        return model.isDone(slot)
    }

    var body: some View {
        ZStack {
            Color.lbNavy.ignoresSafeArea()
            if model.payload.locked {
                Text(
                    model.payload.reason == "pro"
                        ? "LiftBig Pro unlocks the watch."
                        : "Open a workout on your iPhone."
                )
                .font(.footnote)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            } else {
                ViewThatFits(in: .vertical) {
                    workout(value: 20, control: 30, spacing: 3)
                    workout(value: 17, control: 26, spacing: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .transaction { $0.animation = nil }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.syncRestFromClock(hapticStep: false)
                model.ensureRuntime()
            }
        }
    }

    private func workout(value: CGFloat, control: CGFloat, spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            HStack(spacing: 4) {
                pill("Home", filled: false) { model.goHome() }
                if model.restRemaining > 0 {
                    pill(model.restPaused ? "Resume" : "Pause", filled: !model.restPaused) {
                        if model.restPaused {
                            model.resumeRest()
                        } else {
                            model.pauseRest()
                        }
                    }
                    pill("Cancel", filled: false) { model.cancelRest() }
                } else {
                    pill("Finish", filled: true) { model.finishWorkout() }
                }
            }
            HStack(spacing: 2) {
                navButton(system: "chevron.left", enabled: model.viewIndex > 0, size: control) {
                    model.move(by: -1)
                }
                Text(model.viewed?.exerciseName ?? model.payload.exerciseName ?? "Exercise")
                    .font(.system(size: value * 0.7, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity)
                navButton(system: "chevron.right", enabled: model.viewIndex < model.lineup.count - 1, size: control) {
                    model.move(by: 1)
                }
            }
            Text(setLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(setIsDone ? Color.lbOrange : Color.lbMuted)
                .lineLimit(1)
            adjustRow(
                "\(model.displayWeight()) \(model.payload.weightUnit ?? "lb")",
                value: value,
                control: control,
                tint: .white
            ) { model.adjustWeight(by: -model.weightStep) } plus: { model.adjustWeight(by: model.weightStep) }
            adjustRow(
                "\(model.displayReps()) reps",
                value: value,
                control: control,
                tint: .white
            ) { model.adjustReps(by: -1) } plus: { model.adjustReps(by: 1) }
            adjustRow(
                restText,
                value: value * 0.72,
                control: control * 0.9,
                tint: model.restRemaining > 0 && !model.restPaused ? Color.lbOrange : .white
            ) { model.adjustRest(by: -5) } plus: { model.adjustRest(by: 5) }
            Button {
                model.toggleSetDone()
            } label: {
                Text(setIsDone ? "Undo" : "Set done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(setIsDone ? Color.lbOrange : Color.lbNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: control + 2)
                    .background(Capsule().fill(setIsDone ? Color.lbButton : Color.lbOrange))
                    .overlay(Capsule().stroke(Color.lbOrange, lineWidth: setIsDone ? 1.5 : 0))
            }
            .buttonStyle(LbPressStyle())
        }
        .padding(.horizontal, 4)
    }

    private var setLabel: String {
        let number = (model.viewed?.setIndex ?? model.payload.currentSetIndex ?? 0) + 1
        let count = model.viewed?.setCount ?? model.payload.setCount ?? 1
        var text = "Set \(number) of \(count)"
        if setIsDone { text += "  logged" }
        return text
    }

    private var restText: String {
        if model.restRemaining > 0 && model.restPaused {
            return "Paused \(model.clock(model.restRemaining))"
        }
        let seconds = model.restRemaining > 0 ? model.restRemaining : model.restPreset
        return "Rest \(model.clock(seconds))"
    }

    private func navButton(system: String, enabled: Bool, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(enabled ? Color.lbOrange : Color.lbDim)
                .frame(width: size, height: size)
                .background(Circle().fill(enabled ? Color.lbButton : Color.lbDisabled))
                .overlay(Circle().stroke(enabled ? Color.lbOrange : Color.lbDim, lineWidth: 1.5))
        }
        .buttonStyle(LbPressStyle())
        .disabled(!enabled)
    }

    private func adjustRow(
        _ label: String,
        value: CGFloat,
        control: CGFloat,
        tint: Color,
        minus: @escaping () -> Void,
        plus: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 2) {
            roundStep("-", size: control, action: minus)
            Text(label)
                .font(.system(size: value, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
            roundStep("+", size: control, action: plus)
        }
    }

    private func roundStep(_ title: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: size * 0.62, weight: .semibold))
                .foregroundStyle(Color.lbOrange)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.lbButton))
                .overlay(Circle().stroke(Color.lbOrange, lineWidth: 1.5))
        }
        .buttonStyle(LbPressStyle())
    }

    private func pill(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(filled ? Color.lbNavy : Color.lbOrange)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(Capsule().fill(filled ? Color.lbOrange : Color.lbButton))
                .overlay(Capsule().stroke(Color.lbOrange, lineWidth: filled ? 0 : 1.5))
        }
        .buttonStyle(LbPressStyle())
    }
}

private struct LbPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

private extension Color {
    static let lbNavy = Color(red: 10 / 255, green: 15 / 255, blue: 30 / 255)
    static let lbOrange = Color(red: 1, green: 106 / 255, blue: 26 / 255)
    static let lbMuted = Color(red: 154 / 255, green: 164 / 255, blue: 184 / 255)
    static let lbButton = Color(red: 22 / 255, green: 32 / 255, blue: 51 / 255)
    static let lbDim = Color(red: 58 / 255, green: 68 / 255, blue: 88 / 255)
    static let lbDisabled = Color(red: 18 / 255, green: 24 / 255, blue: 38 / 255)
}

/// Extended runtime plus Always On keeps the workout on screen while the
/// display dims. The watch provisioning profile has no HealthKit capability,
/// so this is not an HKWorkoutSession. Finish asks the iPhone to write Health.
final class WorkoutRuntime: NSObject, WKExtendedRuntimeSessionDelegate {
    private var extended: WKExtendedRuntimeSession?
    private var started = false
    private var leaving = false

    func startIfNeeded() {
        guard !started, !leaving else { return }
        started = true
        beginSession()
    }

    func stopKeepingAwake() {
        started = false
        extended?.invalidate()
        extended = nil
    }

    func leaveToWatchFace() {
        leaving = true
        started = false
        extended?.invalidate()
        extended = nil
        exit(0)
    }

    private func beginSession() {
        guard !leaving else { return }
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        extended = session
        session.start()
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        guard started, !leaving else { return }
        beginSession()
    }

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {}
}
