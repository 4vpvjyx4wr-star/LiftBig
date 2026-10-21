package com.liftbig.app.dev

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.exception.InvalidStateException
import com.garmin.android.connectiq.exception.ServiceUnavailableException
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

/**
 * Sends the workout session to the Connect IQ app and forwards
 * `Communications.transmit` messages to Dart on `liftbig/companion`.
 *
 * Garmin Connect has to be installed. If the SDK cannot start, or no watch is
 * connected, the session stays on the phone and nothing is reported as delivered.
 */
object CompanionBridge {
    /** App id from `LiftBig/garmin/liftbig/manifest.xml`. */
    private const val GARMIN_APP_ID = "c3a1e7b24d584f0a9b6e2f7a1d8c0e44"

    private val main = Handler(Looper.getMainLooper())
    private val app = IQApp(GARMIN_APP_ID)
    private val listening = mutableSetOf<Long>()

    private var channel: MethodChannel? = null
    private var connectIQ: ConnectIQ? = null
    private var ready = false
    private var pendingSession: Any? = null

    fun attach(context: Context, messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, "liftbig/companion")
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "publishSession" -> {
                    val json = call.argument<String>("sessionJson")
                        ?: """{"version":1,"locked":true,"reason":"idle"}"""
                    publish(json)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        start(context.applicationContext)
    }

    private fun start(context: Context) {
        if (connectIQ != null) return
        try {
            val iq = ConnectIQ.getInstance(context, ConnectIQ.IQConnectType.WIRELESS)
            connectIQ = iq
            iq.initialize(
                context,
                false,
                object : ConnectIQ.ConnectIQListener {
                    override fun onSdkReady() {
                        ready = true
                        listenKnownDevices()
                        pendingSession?.let { send(it) }
                    }

                    override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus) {
                        ready = false
                    }

                    override fun onSdkShutDown() {
                        ready = false
                        listening.clear()
                    }
                },
            )
        } catch (_: Throwable) {
            ready = false
            connectIQ = null
        }
    }

    private fun publish(json: String) {
        val payload = sessionPayload(json) ?: return
        pendingSession = payload
        if (!ready) return
        send(payload)
    }

    private fun send(payload: Any) {
        val iq = connectIQ ?: return
        val devices = connectedDevices(iq)
        if (devices.isEmpty()) return
        for (device in devices) {
            listen(iq, device)
            try {
                iq.sendMessage(device, app, payload) { _, _, _ -> }
            } catch (_: InvalidStateException) {
            } catch (_: ServiceUnavailableException) {
            }
        }
    }

    private fun listenKnownDevices() {
        val iq = connectIQ ?: return
        val devices = try {
            iq.knownDevices ?: emptyList()
        } catch (_: InvalidStateException) {
            emptyList()
        } catch (_: ServiceUnavailableException) {
            emptyList()
        }
        for (device in devices) listen(iq, device)
    }

    private fun listen(iq: ConnectIQ, device: IQDevice) {
        val id = device.deviceIdentifier
        if (!listening.add(id)) return
        try {
            iq.registerForAppEvents(device, app) { _, _, message, _ ->
                val json = messageJson(message) ?: return@registerForAppEvents
                main.post {
                    channel?.invokeMethod("companionMessage", mapOf("messageJson" to json))
                }
            }
        } catch (_: InvalidStateException) {
            listening.remove(id)
        }
    }

    private fun connectedDevices(iq: ConnectIQ): List<IQDevice> {
        return try {
            val connected = iq.connectedDevices ?: emptyList()
            if (connected.isNotEmpty()) return connected
            (iq.knownDevices ?: emptyList()).filter { device ->
                iq.getDeviceStatus(device) == IQDevice.IQDeviceStatus.CONNECTED
            }
        } catch (_: InvalidStateException) {
            emptyList()
        } catch (_: ServiceUnavailableException) {
            emptyList()
        }
    }

    /** The watch stores `message.data` as a dictionary, so send a map. */
    private fun sessionPayload(json: String): Any? {
        return try {
            fromJson(JSONObject(json))
        } catch (_: Throwable) {
            null
        }
    }

    private fun fromJson(value: Any?): Any? {
        return when (value) {
            null, JSONObject.NULL -> null
            is JSONObject -> {
                val map = LinkedHashMap<String, Any?>()
                val keys = value.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    map[key] = fromJson(value.get(key))
                }
                map
            }
            is JSONArray -> List(value.length()) { index -> fromJson(value.get(index)) }
            is Double ->
                if (value % 1.0 == 0.0 && value <= Int.MAX_VALUE && value >= Int.MIN_VALUE) {
                    value.toInt()
                } else {
                    value
                }
            is Long ->
                if (value <= Int.MAX_VALUE && value >= Int.MIN_VALUE) value.toInt() else value
            else -> value
        }
    }

    private fun messageJson(message: List<*>?): String? {
        if (message.isNullOrEmpty()) return null
        val payload: Any? = if (message.size == 1) message[0] else message
        val encoded = toJson(payload) ?: return null
        return encoded.toString()
    }

    private fun toJson(value: Any?): Any? {
        return when (value) {
            null -> null
            is Map<*, *> -> JSONObject().apply {
                value.forEach { (key, item) ->
                    put(key.toString(), toJson(item) ?: JSONObject.NULL)
                }
            }
            is List<*> -> JSONArray().apply {
                value.forEach { put(toJson(it) ?: JSONObject.NULL) }
            }
            is Array<*> -> JSONArray().apply {
                value.forEach { put(toJson(it) ?: JSONObject.NULL) }
            }
            is Boolean, is Int, is Long, is Double, is String -> value
            is Number -> value.toDouble()
            else -> value.toString()
        }
    }
}
