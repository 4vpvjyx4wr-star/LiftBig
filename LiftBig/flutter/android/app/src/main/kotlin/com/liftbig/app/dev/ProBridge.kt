package com.liftbig.app.dev

import android.app.Activity
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Play Billing status and purchase for the existing Pro subscriptions.
 * A missing Play Store reports `active: false`. The journal is not gated here.
 */
object ProBridge {
    private val productIds = listOf("liftbig.pro.monthly", "liftbig.pro.yearly")

    private var billing: BillingClient? = null
    private var pendingPurchase: MethodChannel.Result? = null

    fun attach(activity: Activity, messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, "liftbig/pro")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getStatus", "restore" -> queryActive(activity) { active ->
                    activity.runOnUiThread { result.success(mapOf("active" to active)) }
                }
                "purchase" -> purchase(activity, call.argument<String>("productId"), result)
                "loadProducts" -> loadProducts(activity) { products ->
                    activity.runOnUiThread { result.success(mapOf("products" to products)) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun client(activity: Activity): BillingClient {
        return billing ?: BillingClient.newBuilder(activity)
            .setListener { result, purchases -> onPurchasesUpdated(activity, result, purchases) }
            .enablePendingPurchases(
                PendingPurchasesParams.newBuilder().enableOneTimeProducts().build(),
            )
            .build()
            .also { billing = it }
    }

    private fun withBilling(
        activity: Activity,
        onReady: (BillingClient) -> Unit,
        onUnavailable: () -> Unit,
    ) {
        val client = client(activity)
        if (client.isReady) {
            onReady(client)
            return
        }
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    onReady(client)
                } else {
                    onUnavailable()
                }
            }

            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun queryActive(activity: Activity, done: (Boolean) -> Unit) {
        withBilling(
            activity,
            onReady = { client ->
                val params = QueryPurchasesParams.newBuilder()
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
                client.queryPurchasesAsync(params) { result, purchases ->
                    if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                        done(false)
                        return@queryPurchasesAsync
                    }
                    done(purchases.any { it.isOwnedPro() })
                }
            },
            onUnavailable = { done(false) },
        )
    }

    private fun purchase(activity: Activity, productId: String?, result: MethodChannel.Result) {
        if (productId.isNullOrBlank()) {
            result.success(mapOf("active" to false, "message" to "Missing product."))
            return
        }
        withBilling(
            activity,
            onReady = { client ->
                val product = QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(productId)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
                val params = QueryProductDetailsParams.newBuilder()
                    .setProductList(listOf(product))
                    .build()
                client.queryProductDetailsAsync(params) { billingResult, detailsResult ->
                    val match = detailsResult.productDetailsList.firstOrNull()
                    val offer = match?.subscriptionOfferDetails?.firstOrNull()?.offerToken
                    if (
                        billingResult.responseCode != BillingClient.BillingResponseCode.OK ||
                        match == null ||
                        offer == null
                    ) {
                        activity.runOnUiThread {
                            result.success(
                                mapOf(
                                    "active" to false,
                                    "message" to "That Pro product is not available yet.",
                                ),
                            )
                        }
                        return@queryProductDetailsAsync
                    }
                    val flow = BillingFlowParams.newBuilder()
                        .setProductDetailsParamsList(
                            listOf(
                                BillingFlowParams.ProductDetailsParams.newBuilder()
                                    .setProductDetails(match)
                                    .setOfferToken(offer)
                                    .build(),
                            ),
                        )
                        .build()
                    pendingPurchase?.let { previous ->
                        activity.runOnUiThread {
                            previous.success(
                                mapOf("active" to false, "message" to "Purchase cancelled."),
                            )
                        }
                    }
                    pendingPurchase = result
                    activity.runOnUiThread { client.launchBillingFlow(activity, flow) }
                }
            },
            onUnavailable = {
                activity.runOnUiThread {
                    result.success(
                        mapOf("active" to false, "message" to "Play Billing is unavailable."),
                    )
                }
            },
        )
    }

    private fun loadProducts(activity: Activity, done: (List<Map<String, String>>) -> Unit) {
        withBilling(
            activity,
            onReady = { client ->
                val products = productIds.map { id ->
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(id)
                        .setProductType(BillingClient.ProductType.SUBS)
                        .build()
                }
                val params = QueryProductDetailsParams.newBuilder()
                    .setProductList(products)
                    .build()
                client.queryProductDetailsAsync(params) { _, detailsResult ->
                    done(
                        detailsResult.productDetailsList.map { detail ->
                            mapOf(
                                "id" to detail.productId,
                                "displayPrice" to (detail.formattedPrice() ?: ""),
                            )
                        },
                    )
                }
            },
            onUnavailable = { done(emptyList()) },
        )
    }

    private fun onPurchasesUpdated(
        activity: Activity,
        result: BillingResult,
        purchases: List<Purchase>?,
    ) {
        val pending = pendingPurchase ?: return
        pendingPurchase = null
        if (result.responseCode == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) {
            queryActive(activity) { active ->
                activity.runOnUiThread { pending.success(mapOf("active" to active)) }
            }
            return
        }
        val bought = purchases?.filter { it.isOwnedPro() }.orEmpty()
        val client = billing
        if (client != null) {
            for (purchase in bought) {
                if (purchase.isAcknowledged) continue
                val params = AcknowledgePurchaseParams.newBuilder()
                    .setPurchaseToken(purchase.purchaseToken)
                    .build()
                client.acknowledgePurchase(params) { }
            }
        }
        val active = result.responseCode == BillingClient.BillingResponseCode.OK && bought.isNotEmpty()
        val message = when (result.responseCode) {
            BillingClient.BillingResponseCode.USER_CANCELED -> "Purchase cancelled."
            BillingClient.BillingResponseCode.OK -> null
            else -> "Purchase could not be completed."
        }
        val payload = mutableMapOf<String, Any>("active" to active)
        if (message != null) payload["message"] = message
        activity.runOnUiThread { pending.success(payload) }
    }

    private fun Purchase.isOwnedPro(): Boolean {
        return purchaseState == Purchase.PurchaseState.PURCHASED &&
            products.any { it in productIds }
    }

    private fun ProductDetails.formattedPrice(): String? {
        return subscriptionOfferDetails
            ?.firstOrNull()
            ?.pricingPhases
            ?.pricingPhaseList
            ?.firstOrNull()
            ?.formattedPrice
    }
}
