package com.liftbig.app.dev

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterFragmentActivity() {
    private var alarmPlayer: MediaPlayer? = null
    private var focusRequest: AudioFocusRequest? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        CompanionBridge.attach(this, messenger)
        ProBridge.attach(this, messenger)
        MethodChannel(messenger, "liftbig/rest_alarm").setMethodCallHandler { call, result ->
            when (call.method) {
                "deviceTimeZone" -> result.success(TimeZone.getDefault().id)
                "startKeepAlive" -> result.success(false)
                "stopKeepAlive" -> {
                    stopAlarm()
                    result.success(true)
                }
                "play" -> result.success(
                    playAlarm(
                        call.argument<Boolean>("loop") == true,
                        call.argument<String>("soundId"),
                    )
                )
                "haptic" -> result.success(playHaptic())
                else -> result.notImplemented()
            }
        }
    }

    private fun alarmAttributes(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    private fun alarmRes(soundId: String?): Int {
        return when (soundId) {
            "bell" -> R.raw.bell
            "chime" -> R.raw.chime
            "horn" -> R.raw.horn
            else -> R.raw.rest_alarm
        }
    }

    private fun playAlarm(loop: Boolean, soundId: String?): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        stopAlarm()
        requestDuck(audioManager)
        val res = alarmRes(soundId)
        var player = MediaPlayer.create(applicationContext, res)
        if (player == null && res != R.raw.rest_alarm) {
            player = MediaPlayer.create(applicationContext, R.raw.rest_alarm)
        }
        if (player == null) {
            abandonDuck(audioManager)
            return false
        }
        player.setAudioAttributes(alarmAttributes())
        player.isLooping = loop
        player.setOnCompletionListener {
            if (it.isLooping) return@setOnCompletionListener
            it.release()
            if (alarmPlayer == it) alarmPlayer = null
            abandonDuck(audioManager)
        }
        player.setOnErrorListener { failed, _, _ ->
            failed.release()
            if (alarmPlayer == failed) alarmPlayer = null
            abandonDuck(audioManager)
            true
        }
        alarmPlayer = player
        player.start()
        return true
    }

    private fun stopAlarm() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        alarmPlayer?.setOnCompletionListener(null)
        alarmPlayer?.stop()
        alarmPlayer?.release()
        alarmPlayer = null
        abandonDuck(audioManager)
    }

    private fun requestDuck(audioManager: AudioManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(alarmAttributes())
                .setOnAudioFocusChangeListener { }
                .build()
            focusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK,
            )
        }
    }

    private fun abandonDuck(audioManager: AudioManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = focusRequest
            if (request != null) {
                audioManager.abandonAudioFocusRequest(request)
                focusRequest = null
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    private fun playHaptic(): Boolean {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!vibrator.hasVibrator()) return false
        val timings = longArrayOf(0, 90, 70, 90, 70, 180, 80, 90, 70, 220, 90, 140)
        val amplitudes = intArrayOf(0, 255, 0, 200, 0, 255, 0, 220, 0, 255, 0, 180)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(timings, -1)
        }
        return true
    }
}
