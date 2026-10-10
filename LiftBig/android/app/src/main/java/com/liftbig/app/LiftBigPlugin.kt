package com.liftbig.app

import androidx.activity.result.ActivityResult
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeightRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryProductDetailsResult
import com.android.billingclient.api.QueryPurchasesParams
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.ActivityCallback
import com.getcapacitor.annotation.CapacitorPlugin
import kotlinx.coroutines.runBlocking
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneOffset
import kotlin.math.abs

@CapacitorPlugin(name = "LiftBig")
class LiftBigPlugin : Plugin() {
    private val monthlyId = "liftbig.pro.monthly"
    private val yearlyId = "liftbig.pro.yearly"
    private val healthPermissions = setOf(
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getReadPermission(HeightRecord::class),
        HealthPermission.getWritePermission(ExerciseSessionRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class),
    )
    private var billing: BillingClient? = null
    private var pendingPurchase: PluginCall? = null

    @PluginMethod
    fun requestHealthAccess(call: PluginCall) {
        val status = HealthConnectClient.getSdkStatus(context)
        if (status != HealthConnectClient.SDK_AVAILABLE) {
            call.resolve(JSObject().put("granted", false))
            return
        }
        val client = HealthConnectClient.getOrCreate(context)
        val granted = runBlocking { client.permissionController.getGrantedPermissions() }
        if (granted.containsAll(healthPermissions)) {
            call.resolve(JSObject().put("granted", true))
            return
        }
        val contract = PermissionController.createRequestPermissionResultContract()
        val intent = contract.createIntent(context, healthPermissions)
        startActivityForResult(call, intent, "healthPermissions")
    }

    @PluginMethod
    fun readHealthProfile(call: PluginCall) {
        val client = healthClientOrNull()
        if (client == null) {
            call.resolve(emptyProfile())
            return
        }
        val profile = runBlocking {
            val now = Instant.now()
            val range = TimeRangeFilter.before(now)
            val weight = client.readRecords(
                ReadRecordsRequest(WeightRecord::class, range, pageSize = 1),
            ).records.lastOrNull()
            val height = client.readRecords(
                ReadRecordsRequest(HeightRecord::class, range, pageSize = 1),
            ).records.lastOrNull()
            val lbs = weight?.weight?.inKilograms?.times(2.2046226218)
            val inches = height?.height?.inMeters?.times(39.3700787402)
            JSObject().put("bodyWeightLbs", lbs ?: JSONObject.NULL).put("heightInches", inches ?: JSONObject.NULL)
        }
        call.resolve(profile)
    }

    @PluginMethod
    fun writeHealthWorkouts(call: PluginCall) {
        val client = healthClientOrNull()
        val raw = call.getString("workoutsJson")
        if (client == null || raw.isNullOrBlank()) {
            call.resolve(JSObject().put("written", 0))
            return
        }
        val written = runBlocking {
            var count = 0
            val rows = JSONArray(raw)
            for (index in 0 until rows.length()) {
                val row = rows.getJSONObject(index)
                if (insertWorkout(client, row)) count += 1
            }
            count
        }
        call.resolve(JSObject().put("written", written))
    }

    @PluginMethod
    fun iCloudAvailable(call: PluginCall) {
        call.resolve(JSObject().put("available", false))
    }

    @PluginMethod
    fun pushICloud(call: PluginCall) {
        call.resolve()
    }

    @PluginMethod
    fun pullICloud(call: PluginCall) {
        call.resolve(JSObject().put("snapshotJson", JSONObject.NULL))
    }

    @PluginMethod
    fun getProStatus(call: PluginCall) {
        queryPurchases { active -> call.resolve(JSObject().put("active", active)) }
    }

    @PluginMethod
    fun purchasePro(call: PluginCall) {
        val productId = call.getString("productId")
        if (productId.isNullOrBlank()) {
            call.resolve(JSObject().put("active", false).put("message", "Missing product."))
            return
        }
        withBilling(
            onReady = { client ->
            val product = QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
            val params = QueryProductDetailsParams.newBuilder().setProductList(listOf(product)).build()
            client.queryProductDetailsAsync(params) { result, detailsResult ->
                val details = detailsResult.productDetailsList
                val match = details.firstOrNull()
                val offer = match?.subscriptionOfferDetails?.firstOrNull()?.offerToken
                if (result.responseCode != BillingClient.BillingResponseCode.OK || match == null || offer == null) {
                    call.resolve(JSObject().put("active", false).put("message", "That Pro product is not available yet."))
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
                pendingPurchase = call
                client.launchBillingFlow(activity, flow)
            }
            },
            onUnavailable = {
                call.resolve(JSObject().put("active", false).put("message", "Play Billing is unavailable."))
            },
        )
    }

    @PluginMethod
    fun restorePro(call: PluginCall) {
        queryPurchases { active -> call.resolve(JSObject().put("active", active)) }
    }

    @PluginMethod
    fun loadProProducts(call: PluginCall) {
        withBilling(
            onReady = { client ->
            val products = listOf(monthlyId, yearlyId).map {
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(it)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
            }
            val params = QueryProductDetailsParams.newBuilder().setProductList(products).build()
            client.queryProductDetailsAsync(params) { _, detailsResult ->
                val array = JSArray()
                detailsResult.productDetailsList.forEach { detail ->
                    val price = detail.subscriptionOfferDetails?.firstOrNull()
                        ?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice
                    array.put(JSObject().put("id", detail.productId).put("displayPrice", price ?: ""))
                }
                call.resolve(JSObject().put("products", array))
            }
            },
            onUnavailable = { call.resolve(JSObject().put("products", JSArray())) },
        )
    }

    @PluginMethod
    fun startRestActivity(call: PluginCall) {
        call.resolve()
    }

    @PluginMethod
    fun endRestActivity(call: PluginCall) {
        call.resolve()
    }

    @PluginMethod
    fun sendWatchSession(call: PluginCall) {
        call.resolve()
    }

    @ActivityCallback
    fun healthPermissions(call: PluginCall, result: ActivityResult) {
        if (result.resultCode == 0 && result.data == null) {
            // The permission sheet closed. Read the granted set either way.
        }
        val client = healthClientOrNull()
        if (client == null) {
            call.resolve(JSObject().put("granted", false))
            return
        }
        val granted = runBlocking { client.permissionController.getGrantedPermissions() }
        call.resolve(JSObject().put("granted", granted.containsAll(healthPermissions)))
    }

    private fun healthClientOrNull(): HealthConnectClient? {
        if (HealthConnectClient.getSdkStatus(context) != HealthConnectClient.SDK_AVAILABLE) return null
        return HealthConnectClient.getOrCreate(context)
    }

    private fun emptyProfile(): JSObject {
        return JSObject().put("bodyWeightLbs", JSONObject.NULL).put("heightInches", JSONObject.NULL)
    }

    private suspend fun insertWorkout(client: HealthConnectClient, row: JSONObject): Boolean {
        val id = row.getString("id")
        val start = Instant.ofEpochMilli(row.getLong("startMs"))
        val end = Instant.ofEpochMilli(row.getLong("endMs"))
        if (!end.isAfter(start)) return false
        val existing = client.readRecords(
            ReadRecordsRequest(
                ExerciseSessionRecord::class,
                TimeRangeFilter.between(start.minusSeconds(120), end.plusSeconds(120)),
            ),
        ).records
        val minutes = abs(end.epochSecond - start.epochSecond) / 60.0
        if (existing.any { it.metadata.clientRecordId == id || abs(it.endTime.epochSecond - it.startTime.epochSecond) / 60.0 - minutes <= 1 }) {
            return false
        }
        val offset = ZoneOffset.systemDefault().rules.getOffset(start)
        val record = ExerciseSessionRecord(
            startTime = start,
            startZoneOffset = offset,
            endTime = end,
            endZoneOffset = offset,
            exerciseType = exerciseType(row.optString("activity")),
            title = "LiftBig",
            metadata = Metadata.manualEntry(clientRecordId = id),
        )
        client.insertRecords(listOf(record))
        return true
    }

    private fun exerciseType(activity: String): Int {
        return when (activity) {
            "walking" -> ExerciseSessionRecord.EXERCISE_TYPE_WALKING
            "running" -> ExerciseSessionRecord.EXERCISE_TYPE_RUNNING
            "cycling" -> ExerciseSessionRecord.EXERCISE_TYPE_BIKING
            "swimming" -> ExerciseSessionRecord.EXERCISE_TYPE_SWIMMING_POOL
            "rowing" -> ExerciseSessionRecord.EXERCISE_TYPE_ROWING_MACHINE
            "hiking" -> ExerciseSessionRecord.EXERCISE_TYPE_HIKING
            "elliptical" -> ExerciseSessionRecord.EXERCISE_TYPE_ELLIPTICAL
            "stairs" -> ExerciseSessionRecord.EXERCISE_TYPE_STAIR_CLIMBING
            "mixedCardio" -> ExerciseSessionRecord.EXERCISE_TYPE_HIGH_INTENSITY_INTERVAL_TRAINING
            else -> ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING
        }
    }

    private fun withBilling(onReady: (BillingClient) -> Unit, onUnavailable: () -> Unit) {
        val client = billing ?: BillingClient.newBuilder(context)
            .setListener { result, purchases -> onPurchasesUpdated(result, purchases) }
            .enablePendingPurchases(
                PendingPurchasesParams.newBuilder().enableOneTimeProducts().build(),
            )
            .build()
            .also { billing = it }
        if (client.isReady) {
            onReady(client)
            return
        }
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) onReady(client)
                else onUnavailable()
            }

            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun queryPurchases(done: (Boolean) -> Unit) {
        withBilling(
            onReady = { client ->
                val params = QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()
                client.queryPurchasesAsync(params) { _, purchases ->
                    done(
                        purchases.any {
                            it.purchaseState == Purchase.PurchaseState.PURCHASED &&
                                (it.products.contains(monthlyId) || it.products.contains(yearlyId))
                        },
                    )
                }
            },
            onUnavailable = { done(false) },
        )
    }

    private fun onPurchasesUpdated(result: BillingResult, purchases: List<Purchase>?) {
        val call = pendingPurchase ?: return
        pendingPurchase = null
        val active = result.responseCode == BillingClient.BillingResponseCode.OK &&
            purchases?.any { it.purchaseState == Purchase.PurchaseState.PURCHASED } == true
        val message = if (result.responseCode == BillingClient.BillingResponseCode.USER_CANCELED) "Purchase cancelled." else null
        val payload = JSObject().put("active", active)
        if (message != null) payload.put("message", message)
        call.resolve(payload)
    }
}
