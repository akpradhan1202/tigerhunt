package com.tigerhunt.tigerhunt.engine

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.tigerhunt.tigerhunt.R

class AudioService(private val context: Context) {
    private var soundPool: SoundPool? = null
    private val soundMap = mutableMapOf<String, Int>()
    var isSoundEnabled: Boolean = true
    var isHapticsEnabled: Boolean = true

    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vm?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    init {
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            soundPool = SoundPool.Builder()
                .setMaxStreams(6)
                .setAudioAttributes(audioAttributes)
                .build()

            loadSound("button_tap", R.raw.button_tap)
            loadSound("goat_move", R.raw.goat_move)
            loadSound("tiger_move", R.raw.tiger_move)
            loadSound("tiger_capture", R.raw.tiger_capture)
            loadSound("capture", R.raw.capture)
            loadSound("game_start", R.raw.game_start)
            loadSound("game_win", R.raw.game_win)
            loadSound("game_lose", R.raw.game_lose)
            loadSound("select", R.raw.select)
            loadSound("timer_warning", R.raw.timer_warning)
        } catch (_: Exception) {
        }
    }

    private fun loadSound(key: String, resId: Int) {
        try {
            soundPool?.let { pool ->
                val id = pool.load(context, resId, 1)
                soundMap[key] = id
            }
        } catch (_: Exception) {
        }
    }

    fun playSound(key: String) {
        if (!isSoundEnabled) return
        try {
            val soundId = soundMap[key]
            if (soundId != null && soundId != 0) {
                soundPool?.play(soundId, 1.0f, 1.0f, 1, 0, 1.0f)
            }
        } catch (_: Exception) {
        }
    }

    fun vibrate(durationMillis: Long = 40) {
        if (!isHapticsEnabled) return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createOneShot(durationMillis, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(durationMillis)
            }
        } catch (_: Exception) {
        }
    }

    fun release() {
        try {
            soundPool?.release()
            soundPool = null
        } catch (_: Exception) {
        }
    }
}
