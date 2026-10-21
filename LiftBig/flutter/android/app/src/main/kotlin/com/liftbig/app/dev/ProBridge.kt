package com.liftbig.app.dev

import android.content.Context
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryPurchasesParams
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Play Billing status for the existing Pro subscriptions.
 * A missing Play Store reports `active: false`. The journal is not gated here.
 */
object ProBridge {
    private val productIds = setOf("liftbig.pro.monthly", "liftbig.pro.yearly")

    private var billing: BillingClient? = null

    fun attach(context: Context, messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, "liftbig/pro")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getStatus", "restore" -> queryActive(context.applicationContext) { active ->
                    result.success(mapOf("active" to active))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun queryActive(context: Context, done: (Boolean) -> Unit) {
        val client = billing ?: BillingClient.newBuilder(context)
            .setListener { _, _ -> }
            .enablePendingPurchases(
                PendingPurchasesParams.newBuilder().enableOneTimeProducts().build(),
            )
            .build()
            .also { billing = it }
        val finish: (Boolean) -> Unit = { active -> done(active) }
        if (client.isReady) {
            query(client, finish)
            return
        }
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    query(client, finish)
                } else {
                    finish(false)
                }
            }

            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun query(client: BillingClient, done: (Boolean) -> Unit) {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
        client.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) {
                done(false)
                return@queryPurchasesAsync
            }
            done(
                purchases.any { purchase ->
                    purchase.purchaseState == Purchase.PurchaseState.PURCHASED &&
                        purchase.products.any { it in productIds }
                },
            )
        }
    }
}
