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

import CoreText
import SwiftUI
import UIKit
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
    var supersetGroupId: String?
    var supersetLabel: String?
    var supersetOrder: Int?
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
    var restEndsAt: Double?
    var restCancelled: Bool?
    var soundEnabled: Bool?
    var restPaused: Bool?
    var restRemaining: Int?
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
    private var playedRestDoneCue = false
    private var soundEnabled = true
    let runtime = WorkoutRuntime()
    var interfaceActive = true
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
        restoreRest()
        requestRestNotificationPermission()
    }

    func noteScene(_ phase: ScenePhase) {
        interfaceActive = phase == .active
        if phase == .active {
            syncRestFromClock()
            ensureRuntime()
            return
        }
        guard restRemaining > 0, !restPaused else { return }
        scheduleRestAlert()
    }

    private func requestRestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                DispatchQueue.main.async { self.scheduleRestAlert() }
            }
        }
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
        let advance = advanceAfterComplete(from: viewIndex)
        if advance.startRest {
            startRest()
        }
        if lineup.indices.contains(advance.index) {
            viewIndex = advance.index
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
        syncRestFromClock()
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
        persistRest()
        let leave = { self.runtime.leaveToWatchFace() }
        if restRemaining > 0, !restPaused {
            syncRestFromClock()
            scheduleRestAlert { _ in leave() }
        } else {
            cancelRestAlert()
            leave()
        }
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
        show(index: viewIndex + delta)
    }

    func show(index: Int) {
        let count = lineup.count
        guard count > 0 else { return }
        let next = min(max(index, 0), count - 1)
        guard next != viewIndex else { return }
        viewIndex = next
    }

    func jumpToOpenSet() {
        let open = openIndex
        guard open != viewIndex else { return }
        viewIndex = open
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

    /// Highest whole number in the text. "8-12" is 12, so the working count
    /// starts at the top of the range.
    private func parseWhole(_ raw: String?) -> Int {
        let text = raw ?? ""
        var best = 0
        var current = 0
        var inNumber = false
        var found = false
        for scalar in text.unicodeScalars {
            if let digit = Int(String(scalar)), scalar.value >= 48, scalar.value <= 57 {
                current = current * 10 + digit
                inNumber = true
                found = true
            } else if inNumber {
                if current > best { best = current }
                current = 0
                inNumber = false
            }
        }
        if inNumber && current > best { best = current }
        return found ? best : 0
    }

    /// A range becomes its top count. A single number and a non-numeric goal stay.
    private func canonicalReps(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }
        if Int(trimmed) != nil { return trimmed }
        let count = parseWhole(trimmed)
        if count <= 0 { return trimmed }
        return String(count)
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
        playedRestDoneCue = false
        restPaused = false
        restRemaining = restPreset
        restEndsAt = Date().addingTimeInterval(TimeInterval(restPreset))
        persistRest()
        scheduleRestAlert()
        WKInterfaceDevice.current().play(.start)
        armRestTimer()
    }

    private func armRestTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.syncRestFromClock()
        }
    }

    func syncRestFromClock() {
        guard let restEndsAt, !restPaused else { return }
        let left = max(0, Int(ceil(restEndsAt.timeIntervalSinceNow)))
        if left <= 0 {
            finishRestAlert()
            return
        }
        if left != restRemaining {
            restRemaining = left
        }
    }

    private func finishRestAlert() {
        restRemaining = 0
        restPaused = false
        restEndsAt = nil
        timer?.invalidate()
        timer = nil
        persistRest()
        playRestDoneCue()
        if RestAlertPlan.cancelPendingWhenRestEnds(interfaceActive: interfaceActive) {
            cancelRestAlert()
        }
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
            let center = UNUserNotificationCenter.current()
            center.getDeliveredNotifications { notes in
                let delivered = notes.contains { $0.request.identifier == RestAlertPlan.identifier }
                DispatchQueue.main.async {
                    if delivered {
                        center.removeDeliveredNotifications(withIdentifiers: [RestAlertPlan.identifier])
                    } else {
                        self.playRestDoneCue()
                    }
                }
            }
            return
        }
        restEndsAt = date
        restRemaining = left
        restPaused = false
        scheduleRestAlert()
        armRestTimer()
    }

    private func scheduleRestAlert(completion: ((Bool) -> Void)? = nil) {
        guard !restPaused, let restEndsAt, let request = RestAlertPlan.makeRequest(endsAt: restEndsAt, now: Date(), soundEnabled: soundEnabled) else {
            completion?(false)
            return
        }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        guard granted, !self.restPaused, let restEndsAt = self.restEndsAt,
                              let fresh = RestAlertPlan.makeRequest(endsAt: restEndsAt, now: Date(), soundEnabled: self.soundEnabled) else {
                            completion?(false)
                            return
                        }
                        RestAlertPlan.submit(fresh, center: center) { error in
                            DispatchQueue.main.async { completion?(error == nil) }
                        }
                    }
                }
            case .authorized, .provisional, .ephemeral:
                RestAlertPlan.submit(request, center: center) { error in
                    DispatchQueue.main.async { completion?(error == nil) }
                }
            default:
                DispatchQueue.main.async { completion?(false) }
            }
        }
    }

    private func cancelRestAlert() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [RestAlertPlan.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [RestAlertPlan.identifier])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.identifier == RestAlertPlan.identifier {
            syncRestFromClock()
            playRestDoneCue()
            return RestAlertPlan.presentationOptions(soundEnabled: soundEnabled)
        }
        return [.banner, .sound]
    }

    private func playRestDoneCue() {
        if playedRestDoneCue { return }
        playedRestDoneCue = true
        RestAlertPlan.playRestDoneHaptic()
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
        return canonicalReps(viewed?.reps ?? payload.targetReps ?? "0")
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

    /// Same-set rotation through a superset. Rest starts only after the last
    /// lift in that round, matching the phone's startsRestAfterSet rule.
    private func advanceAfterComplete(from index: Int) -> (index: Int, startRest: Bool) {
        let slots = lineup
        guard slots.indices.contains(index) else { return (index, true) }
        let slot = slots[index]
        let group = slot.supersetGroupId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if group.isEmpty {
            let next = index + 1 < slots.count ? index + 1 : index
            return (next, true)
        }
        var start = index
        while start > 0 && supersetGroup(slots[start - 1]) == group {
            start -= 1
        }
        var end = index
        while end + 1 < slots.count && supersetGroup(slots[end + 1]) == group {
            end += 1
        }
        var members: [(id: String, order: Int, first: Int)] = []
        for offset in start...end {
            let item = slots[offset]
            if members.contains(where: { $0.id == item.exerciseId }) { continue }
            let order = item.supersetOrder ?? (1_000_000 + members.count)
            members.append((item.exerciseId, order, offset))
        }
        members.sort { lhs, rhs in
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return lhs.first < rhs.first
        }
        let position = members.firstIndex(where: { $0.id == slot.exerciseId }) ?? 0
        if position + 1 < members.count {
            for member in members[(position + 1)...] {
                if let found = findSlot(membersId: member.id, setIndex: slot.setIndex, start: start, end: end) {
                    return (found, false)
                }
            }
        }
        let following = slot.setIndex + 1
        if let first = members.first,
           let found = findSlot(membersId: first.id, setIndex: following, start: start, end: end) {
            return (found, true)
        }
        var after = end + 1
        if after >= slots.count { after = index }
        return (after, true)
    }

    private func supersetGroup(_ slot: WatchSlot) -> String {
        slot.supersetGroupId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func findSlot(membersId: String, setIndex: Int, start: Int, end: Int) -> Int? {
        let slots = lineup
        guard start <= end, slots.indices.contains(start), slots.indices.contains(end) else { return nil }
        for offset in start...end {
            let item = slots[offset]
            if item.exerciseId == membersId && item.setIndex == setIndex { return offset }
        }
        return nil
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
            reps = canonicalReps(slot.reps)
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
        guard let data = json.data(using: .utf8) else { return }
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard var next = try? JSONDecoder().decode(WatchPayload.self, from: data) else { return }
        if var slots = next.lineup {
            for index in slots.indices {
                slots[index].reps = canonicalReps(slots[index].reps)
            }
            next.lineup = slots
        }
        if let target = next.targetReps {
            next.targetReps = canonicalReps(target)
        }
        DispatchQueue.main.async {
            if let object {
                self.adoptPhoneRest(object)
            }
            let dateChanged = next.dateKey != self.payload.dateKey
            let sameWorkout = !dateChanged && self.sameLineup(self.payload.lineup, next.lineup)
            self.payload = next
            if dateChanged { self.restTouched = false }
            if !self.restTouched {
                let incoming = min(300, max(5, next.restSeconds ?? 60))
                self.restPreset = incoming
            }
            if !sameWorkout {
                self.edits = [:]
                self.doneOverrides = [:]
            }
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

    private func sameLineup(_ lhs: [WatchSlot]?, _ rhs: [WatchSlot]?) -> Bool {
        let left = lhs ?? []
        let right = rhs ?? []
        guard left.count == right.count else { return false }
        for index in left.indices {
            if left[index].exerciseId != right[index].exerciseId { return false }
            if left[index].setIndex != right[index].setIndex { return false }
            if left[index].checked != right[index].checked { return false }
            if left[index].reps != right[index].reps { return false }
            if left[index].weightDisplay != right[index].weightDisplay { return false }
        }
        return true
    }

    /// Phone rest is absolute. A missing end leaves a watch-started countdown alone.
    private func adoptPhoneRest(_ dict: [String: Any]) {
        let soundChanged = boolValue(dict["soundEnabled"]) != nil
        if let sound = boolValue(dict["soundEnabled"]) {
            soundEnabled = sound
        }
        if boolValue(dict["restCancelled"]) == true {
            clearPhoneRest()
            return
        }
        if boolValue(dict["restPaused"]) == true {
            let left = intValue(dict["restRemaining"]) ?? restRemaining
            guard left > 0 else {
                clearPhoneRest()
                return
            }
            restPaused = true
            restRemaining = left
            restEndsAt = nil
            timer?.invalidate()
            timer = nil
            persistRest()
            cancelRestAlert()
            return
        }
        if dict.keys.contains("restEndsAt"),
           let seconds = doubleValue(dict["restEndsAt"]),
           seconds > 0 {
            let date = Date(timeIntervalSince1970: seconds)
            let left = Int(ceil(date.timeIntervalSinceNow))
            if left > 0 {
                playedRestDoneCue = false
                restPaused = false
                restEndsAt = date
                restRemaining = left
                persistRest()
                scheduleRestAlert()
                armRestTimer()
                return
            }
        }
        if soundChanged, restRemaining > 0, !restPaused {
            scheduleRestAlert()
        }
    }

    private func clearPhoneRest() {
        timer?.invalidate()
        timer = nil
        restRemaining = 0
        restPaused = false
        restEndsAt = nil
        playedRestDoneCue = true
        persistRest()
        cancelRestAlert()
    }

    private func boolValue(_ value: Any?) -> Bool? {
        if let bool = value as? Bool { return bool }
        if value is NSNull { return nil }
        if let number = value as? NSNumber { return number.boolValue }
        return nil
    }

    private func intValue(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    private func doubleValue(_ value: Any?) -> Double? {
        if value is NSNull { return nil }
        if let number = value as? NSNumber { return number.doubleValue }
        return nil
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

    private var allSetsDone: Bool {
        !model.lineup.isEmpty && model.lineup.allSatisfy { model.isDone($0) }
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
                ScrollView {
                    workout(value: 18, control: 30, spacing: 8)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity)
                }
                .defaultScrollAnchor(.top)
                .contentMargins(0, for: .scrollContent)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
                .onAppear(perform: silenceScrollClicks)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            model.noteScene(phase)
            if phase == .active { silenceScrollClicks() }
        }
    }

    /// ScrollView owns the crown. This only turns off the table-scroll click;
    /// it does not attach a custom crown range.
    private func silenceScrollClicks() {
        let app = WKApplication.shared()
        let controller = app.visibleInterfaceController ?? app.rootInterfaceController
        controller?.isTableScrollingHapticFeedbackEnabled = false
    }

    private func workout(value: CGFloat, control: CGFloat, spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            if model.restRemaining > 0 {
                HStack(spacing: 8) {
                    pill(model.restPaused ? "Resume" : "Pause", filled: !model.restPaused) {
                        if model.restPaused {
                            model.resumeRest()
                        } else {
                            model.pauseRest()
                        }
                    }
                    pill("Cancel", filled: false) { model.cancelRest() }
                }
            } else if allSetsDone {
                pill("Finish", filled: true) { model.finishWorkout() }
            }
            Text(setLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(setIsDone ? Color.lbOrange : Color.lbMuted)
                .lineLimit(1)
            HStack(spacing: 8) {
                navButton(system: "chevron.left", enabled: model.viewIndex > 0, size: control) {
                    model.move(by: -1)
                }
                ExerciseTitle(
                    name: model.viewed?.exerciseName ?? model.payload.exerciseName ?? "Exercise",
                    size: value * 0.7
                )
                navButton(system: "chevron.right", enabled: model.viewIndex < model.lineup.count - 1, size: control) {
                    model.move(by: 1)
                }
            }
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
                value: value,
                control: control,
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
        Button {
            guard enabled else { return }
            action()
        } label: {
            Image(systemName: system)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(enabled ? Color.lbOrange : Color.lbDim)
                .frame(width: size, height: size)
                .background(Circle().fill(enabled ? Color.lbButton : Color.lbDisabled))
                .overlay(Circle().stroke(enabled ? Color.lbOrange : Color.lbDim, lineWidth: 1.5))
        }
        .buttonStyle(LbPressStyle())
        .accessibilityAddTraits(.isButton)
    }

    private func adjustRow(
        _ label: String,
        value: CGFloat,
        control: CGFloat,
        tint: Color,
        minus: @escaping () -> Void,
        plus: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
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
        let fontSize = size * 0.62
        return Button(action: action) {
            ZStack {
                Circle().fill(Color.lbButton)
                Circle().stroke(Color.lbOrange, lineWidth: 1.5)
                Text(title)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(Color.lbOrange)
                    .fixedSize()
                    .offset(StepGlyphShift.offset(for: title, fontSize: fontSize))
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
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

private struct ExerciseTitle: View {
    let name: String
    let size: CGFloat
    @State private var width: CGFloat = 0
    @State private var fullHeight: CGFloat = 0
    @State private var twoLineHeight: CGFloat = 0

    private var font: Font { .system(size: size, weight: .semibold) }

    private var needsMarquee: Bool {
        width > 1 && twoLineHeight > 0 && fullHeight > twoLineHeight + 1
    }

    private var titleHeight: CGFloat {
        if needsMarquee { return max(twoLineHeight / 2, size + 2) }
        if fullHeight > 0, twoLineHeight > 0 { return min(fullHeight, twoLineHeight) }
        return max(size + 4, 16)
    }

    var body: some View {
        ZStack {
            if needsMarquee {
                MarqueeLine(text: name, size: size)
            } else {
                Text(name)
                    .font(font)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: titleHeight)
        .background(measurer)
        .onPreferenceChange(TitleWidthKey.self) { width = $0 }
        .onPreferenceChange(TitleFullHeightKey.self) { fullHeight = $0 }
        .onPreferenceChange(TitleTwoLineKey.self) { twoLineHeight = $0 }
    }

    private var measurer: some View {
        ZStack {
            Text(name)
                .font(font)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: max(width, 1), alignment: .leading)
                .hidden()
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: TitleFullHeightKey.self, value: proxy.size.height)
                })
            Text("Mg\nMg")
                .font(font)
                .hidden()
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: TitleTwoLineKey.self, value: proxy.size.height)
                })
        }
        .background(GeometryReader { proxy in
            Color.clear.preference(key: TitleWidthKey.self, value: proxy.size.width)
        })
        .allowsHitTesting(false)
    }
}

private struct MarqueeLine: View {
    let text: String
    let size: CGFloat
    @State private var textWidth: CGFloat = 0
    @State private var travel: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .background(GeometryReader { textGeo in
                    Color.clear.preference(key: MarqueeWidthKey.self, value: textGeo.size.width)
                })
                .offset(x: travel)
                .frame(width: geo.size.width, alignment: .leading)
                .clipped()
        }
        .clipped()
        .onPreferenceChange(MarqueeWidthKey.self) { width in
            textWidth = width
        }
        .onAppear { start() }
        .onChange(of: text) { _, _ in start() }
        .onChange(of: textWidth) { _, _ in start() }
    }

    private func start() {
        guard textWidth > 8 else { return }
        let distance = textWidth + 16
        travel = 0
        let duration = max(Double(distance) / 28, 2.5)
        withAnimation(.linear(duration: duration).delay(0.8).repeatForever(autoreverses: false)) {
            travel = -distance
        }
    }
}

/// Moves a "+" or "−" so its ink, not the font line box, sits in the middle of
/// the circle. The line box hangs below the baseline, which left these glyphs low.
private enum StepGlyphShift {
    static func offset(for text: String, fontSize: CGFloat) -> CGSize {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: text, attributes: [.font: font])
        )
        let glyph = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        guard glyph.width > 0, glyph.height > 0 else { return .zero }
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        let glyphCenterFromTop = font.ascender - glyph.midY
        let y = font.lineHeight / 2 - glyphCenterFromTop
        let x = width / 2 - glyph.midX
        return CGSize(width: x, height: y)
    }
}

private struct TitleWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct TitleFullHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct TitleTwoLineKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct MarqueeWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
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
