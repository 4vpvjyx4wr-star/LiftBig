import Flutter
import Foundation
import StoreKit

/// StoreKit 2 status for the existing Pro subscriptions.
/// A missing store or an unverified transaction reports `active: false`.
/// The journal is not gated here.
final class ProBridge: NSObject {
    static let shared = ProBridge()

    private let productIds = ["liftbig.pro.monthly", "liftbig.pro.yearly"]

    func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "liftbig/pro", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(["active": false])
                return
            }
            switch call.method {
            case "getStatus":
                Task {
                    let active = await self.isActive()
                    DispatchQueue.main.async { result(["active": active]) }
                }
            case "restore":
                Task {
                    try? await AppStore.sync()
                    let active = await self.isActive()
                    DispatchQueue.main.async { result(["active": active]) }
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func isActive() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if productIds.contains(transaction.productID), transaction.revocationDate == nil {
                return true
            }
        }
        return false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw ProStoreError.unverified
        }
    }
}

private enum ProStoreError: Error {
    case unverified
}
