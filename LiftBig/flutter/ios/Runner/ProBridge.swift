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
            case "purchase":
                let productId = (call.arguments as? [String: Any])?["productId"] as? String
                Task {
                    let payload = await self.purchase(productId)
                    DispatchQueue.main.async { result(payload) }
                }
            case "loadProducts":
                Task {
                    let products = await self.loadProducts()
                    DispatchQueue.main.async { result(["products": products]) }
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func purchase(_ productId: String?) async -> [String: Any] {
        guard let productId, !productId.isEmpty else {
            return ["active": false, "message": "Missing product."]
        }
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                return ["active": false, "message": "That Pro product is not available yet."]
            }
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                return ["active": true]
            case .userCancelled:
                return ["active": false, "message": "Purchase cancelled."]
            case .pending:
                return ["active": false, "message": "Purchase is pending."]
            @unknown default:
                return ["active": false, "message": "Purchase could not be completed."]
            }
        } catch {
            return ["active": false, "message": "Purchase could not be completed."]
        }
    }

    private func loadProducts() async -> [[String: String]] {
        let products = (try? await Product.products(for: productIds)) ?? []
        return products.map { ["id": $0.id, "displayPrice": $0.displayPrice] }
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
