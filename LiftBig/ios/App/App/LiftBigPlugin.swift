import ActivityKit
import Capacitor
import Foundation
import HealthKit
import StoreKit
import UniformTypeIdentifiers
import UserNotifications
import WatchConnectivity

private let proMonthlyId = "liftbig.pro.monthly"
private let proYearlyId = "liftbig.pro.yearly"

class LiftBigBridgeViewController: CAPBridgeViewController, UIDropInteractionDelegate {
    private var backupDropAdded = false

    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(LiftBigPlugin())
        guard !backupDropAdded else { return }
        backupDropAdded = true
        view.addInteraction(UIDropInteraction(delegate: self))
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.hasItemsConforming(toTypeIdentifiers: [
            UTType.json.identifier,
            UTType.plainText.identifier,
            UTType.text.identifier,
            UTType.data.identifier,
        ])
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first else { return }
        let provider = item.itemProvider
        let type = [UTType.json.identifier, UTType.plainText.identifier, UTType.text.identifier, UTType.data.identifier]
            .first { provider.hasItemConformingToTypeIdentifier($0) }
        guard let type else { return }
        provider.loadDataRepresentation(forTypeIdentifier: type) { data, _ in
            guard let data, let text = String(data: data, encoding: .utf8), text.contains("{") else { return }
            DispatchQueue.main.async {
                guard let plugin = self.bridge?.plugin(withName: "LiftBig") as? LiftBigPlugin else { return }
                plugin.notifyListeners("backupFile", data: ["json": text])
            }
        }
    }
}

@objc(LiftBigPlugin)
public class LiftBigPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LiftBigPlugin"
    public let jsName = "LiftBig"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestHealthAccess", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "readHealthProfile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "writeHealthWorkouts", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "iCloudAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pushICloud", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pullICloud", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getProStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchasePro", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restorePro", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loadProProducts", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startRestActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "endRestActivity", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "scheduleRestAlert", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sendWatchSession", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isSimulator", returnType: CAPPluginReturnPromise),
    ]

    private let health = HKHealthStore()
    private let proIds = [proMonthlyId, proYearlyId]

    override public func load() {
        PhoneWatchRelay.shared.plugin = self
        PhoneWatchRelay.shared.activate()
    }

    @objc func requestHealthAccess(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.resolve(["granted": false])
            return
        }
        var share = Set<HKSampleType>([HKWorkoutType.workoutType()])
        if let energy = energyType { share.insert(energy) }
        var read = Set<HKObjectType>([HKWorkoutType.workoutType()])
        if let mass = bodyMassType { read.insert(mass) }
        if let height = heightType { read.insert(height) }
        Task {
            do {
                try await health.requestAuthorization(toShare: share, read: read)
                let granted = health.authorizationStatus(for: HKWorkoutType.workoutType()) == .sharingAuthorized
                call.resolve(["granted": granted])
            } catch {
                call.resolve(["granted": false])
            }
        }
    }

    @objc func readHealthProfile(_ call: CAPPluginCall) {
        Task {
            let weight = await latestQuantity(.bodyMass, unit: .pound())
            let height = await latestQuantity(.height, unit: .inch())
            call.resolve([
                "bodyWeightLbs": weight.map { NSNumber(value: $0) } ?? NSNull(),
                "heightInches": height.map { NSNumber(value: $0) } ?? NSNull(),
            ])
        }
    }

    @objc func writeHealthWorkouts(_ call: CAPPluginCall) {
        guard let raw = call.getString("workoutsJson"),
              let data = raw.data(using: .utf8),
              let rows = try? JSONDecoder().decode([HealthWrite].self, from: data) else {
            call.resolve(["written": 0])
            return
        }
        Task {
            var written = 0
            for row in rows {
                if await writeWorkout(row) { written += 1 }
            }
            call.resolve(["written": written])
        }
    }

    @objc func iCloudAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": ubiquityDirectory() != nil])
    }

    @objc func pushICloud(_ call: CAPPluginCall) {
        guard let json = call.getString("snapshotJson"), let file = snapshotFileURL() else {
            call.reject("iCloud is unavailable")
            return
        }
        do {
            try json.write(to: file, atomically: true, encoding: .utf8)
            call.resolve()
        } catch {
            call.reject("Could not write iCloud snapshot")
        }
    }

    @objc func pullICloud(_ call: CAPPluginCall) {
        guard let file = snapshotFileURL() else {
            call.resolve(["snapshotJson": NSNull()])
            return
        }
        if !FileManager.default.fileExists(atPath: file.path) {
            call.resolve(["snapshotJson": NSNull()])
            return
        }
        try? FileManager.default.startDownloadingUbiquitousItem(at: file)
        guard let text = try? String(contentsOf: file, encoding: .utf8) else {
            call.resolve(["snapshotJson": NSNull()])
            return
        }
        call.resolve(["snapshotJson": text])
    }

    @objc func getProStatus(_ call: CAPPluginCall) {
        Task { call.resolve(["active": await proIsActive()]) }
    }

    @objc func purchasePro(_ call: CAPPluginCall) {
        guard let productId = call.getString("productId") else {
            call.resolve(["active": false, "message": "Missing product."])
            return
        }
        Task {
            do {
                let products = try await Product.products(for: [productId])
                guard let product = products.first else {
                    call.resolve(["active": false, "message": "That Pro product is not available yet."])
                    return
                }
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try Self.checkVerified(verification)
                    await transaction.finish()
                    call.resolve(["active": true])
                case .userCancelled:
                    call.resolve(["active": false, "message": "Purchase cancelled."])
                case .pending:
                    call.resolve(["active": false, "message": "Purchase is pending."])
                @unknown default:
                    call.resolve(["active": false])
                }
            } catch {
                call.resolve(["active": false, "message": "Purchase could not be completed."])
            }
        }
    }

    @objc func restorePro(_ call: CAPPluginCall) {
        Task {
            try? await AppStore.sync()
            call.resolve(["active": await proIsActive()])
        }
    }

    @objc func loadProProducts(_ call: CAPPluginCall) {
        Task {
            let products = (try? await Product.products(for: proIds)) ?? []
            let payload: [[String: String]] = products.map { ["id": $0.id, "displayPrice": $0.displayPrice] }
            call.resolve(["products": payload])
        }
    }

    @objc func startRestActivity(_ call: CAPPluginCall) {
        let endsAtMs = call.getDouble("endsAtMs") ?? 0
        let title = call.getString("title") ?? "Rest"
        let endsAt = Date(timeIntervalSince1970: endsAtMs / 1000)
        Task {
            await endRestActivities()
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                call.resolve()
                return
            }
            let attributes = RestActivityAttributes(title: title)
            let state = RestActivityAttributes.ContentState(endsAt: endsAt)
            _ = try? Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil))
            call.resolve()
        }
    }

    @objc func endRestActivity(_ call: CAPPluginCall) {
        Task {
            await endRestActivities()
            call.resolve()
        }
    }

    /// Uses the system notification sound. On iPhone that sound is what triggers the vibration.
    @objc func scheduleRestAlert(_ call: CAPPluginCall) {
        let endsAtMs = call.getDouble("endsAtMs") ?? 0
        let fire = Date(timeIntervalSince1970: endsAtMs / 1000)
        let interval = fire.timeIntervalSinceNow
        guard interval > 0.5 else {
            call.resolve()
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Time to Lift Big"
        content.body = "Your rest timer is done — get back to it!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "41001", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error {
                    call.reject(error.localizedDescription)
                } else {
                    call.resolve()
                }
            }
        }
    }

    @objc func sendWatchSession(_ call: CAPPluginCall) {
        let json = call.getString("sessionJson") ?? "{\"version\":1,\"locked\":true}"
        PhoneWatchRelay.shared.send(json)
        call.resolve()
    }

    @objc func isSimulator(_ call: CAPPluginCall) {
        #if targetEnvironment(simulator)
        call.resolve(["simulator": true])
        #else
        call.resolve(["simulator": false])
        #endif
    }

    private var bodyMassType: HKQuantityType? { HKQuantityType.quantityType(forIdentifier: .bodyMass) }
    private var heightType: HKQuantityType? { HKQuantityType.quantityType(forIdentifier: .height) }
    private var energyType: HKQuantityType? { HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) }

    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let quantity = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: quantity)
            }
            health.execute(query)
        }
    }

    private func writeWorkout(_ row: HealthWrite) async -> Bool {
        if await workoutExists(row) { return false }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType(row.activity)
        let builder = HKWorkoutBuilder(healthStore: health, configuration: configuration, device: .local())
        let start = Date(timeIntervalSince1970: row.startMs / 1000)
        let end = Date(timeIntervalSince1970: row.endMs / 1000)
        do {
            try await builder.beginCollection(at: start)
            try await builder.addMetadata([
                HKMetadataKeySyncIdentifier: row.id,
                HKMetadataKeySyncVersion: 1,
            ])
            if let kcal = row.energyKcal, let type = energyType, kcal > 0 {
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
                let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end)
                try await builder.addSamples([sample])
            }
            if let meters = row.distanceMeters, meters > 0,
               let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
                let quantity = HKQuantity(unit: .meter(), doubleValue: meters)
                let sample = HKQuantitySample(type: distanceType, quantity: quantity, start: start, end: end)
                try await builder.addSamples([sample])
            }
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
            return true
        } catch {
            builder.discardWorkout()
            return false
        }
    }

    private func workoutExists(_ row: HealthWrite) async -> Bool {
        await withCheckedContinuation { continuation in
            let idPredicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier, allowedValues: [row.id])
            let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: idPredicate, limit: 1, sortDescriptors: nil) { _, samples, _ in
                if let samples, !samples.isEmpty {
                    continuation.resume(returning: true)
                    return
                }
                let start = Date(timeIntervalSince1970: row.startMs / 1000)
                let end = Date(timeIntervalSince1970: row.endMs / 1000)
                let window = HKQuery.predicateForSamples(withStart: start.addingTimeInterval(-120), end: end.addingTimeInterval(120), options: [])
                let minutes = abs(row.endMs - row.startMs) / 60000
                let activity = self.activityType(row.activity)
                let overlap = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: window, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, found, _ in
                    let workouts = found as? [HKWorkout] ?? []
                    let match = workouts.contains { workout in
                        workout.workoutActivityType == activity
                            && abs(workout.duration / 60 - minutes) <= 1
                    }
                    continuation.resume(returning: match)
                }
                self.health.execute(overlap)
            }
            health.execute(query)
        }
    }

    private func activityType(_ name: String) -> HKWorkoutActivityType {
        switch name {
        case "walking": return .walking
        case "running": return .running
        case "cycling": return .cycling
        case "swimming": return .swimming
        case "rowing": return .rowing
        case "hiking": return .hiking
        case "elliptical": return .elliptical
        case "stairs": return .stairs
        case "mixedCardio": return .mixedCardio
        default: return .traditionalStrengthTraining
        }
    }

    private func ubiquityDirectory() -> URL? {
        guard let base = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.liftbig.app") else {
            return nil
        }
        let docs = base.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs
    }

    private func snapshotFileURL() -> URL? {
        ubiquityDirectory()?.appendingPathComponent("liftbig-snapshot.json")
    }

    private func proIsActive() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? Self.checkVerified(result) else { continue }
            if proIds.contains(transaction.productID), transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.unverified
        }
    }

    private func endRestActivities() async {
        for activity in Activity<RestActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

private enum StoreError: Error { case unverified }

private struct HealthWrite: Decodable {
    let id: String
    let activity: String
    let startMs: Double
    let endMs: Double
    let energyKcal: Double?
    let distanceMeters: Double?
}

final class PhoneWatchRelay: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchRelay()
    weak var plugin: LiftBigPlugin?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ json: String) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        try? WCSession.default.updateApplicationContext(["sessionJson": json])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliver(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        deliver(userInfo)
    }

    private func deliver(_ payload: [String: Any]) {
        guard let json = payload["messageJson"] as? String else { return }
        plugin?.notifyListeners("companionMessage", data: ["messageJson": json])
    }
}
