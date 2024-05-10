package io.nextsense.android.budz.manager

import android.content.Context
import android.media.MediaPlayer
import android.media.SoundPool
import android.net.Uri
import io.nextsense.android.budz.R

data class AudioSample(
    val id: String,
    val name: String,
    val resId: Int
)

object SoundsManager {

    enum class AudioSamples {
        BROWN_NOISE,
        PINK_NOISE,
        WHITE_NOISE,
        FAN_SOUND;

        fun key() = name.lowercase()
    }

    val defaultFallAsleepAudioSample = AudioSamples.FAN_SOUND
    val defaultStayAsleepAudioSample = AudioSamples.BROWN_NOISE

    private val _idToSampleMap = mapOf(
        AudioSamples.BROWN_NOISE.key() to
                AudioSample(AudioSamples.BROWN_NOISE.key(),"Brown Noise", R.raw.brown_noise),
        AudioSamples.PINK_NOISE.key() to
                AudioSample(AudioSamples.PINK_NOISE.key(), "Pink Noise", R.raw.pink_noise),
        AudioSamples.WHITE_NOISE.key() to
                AudioSample(AudioSamples.WHITE_NOISE.key(), "White Noise", R.raw.white_noise),
        AudioSamples.FAN_SOUND.key() to
                AudioSample(AudioSamples.FAN_SOUND.key(), "Fan Sound", R.raw.fan_sound)
    )

    val fallAsleepSamples = listOf(
        idToSample(AudioSamples.BROWN_NOISE.key()),
        idToSample(AudioSamples.PINK_NOISE.key()),
        idToSample(AudioSamples.WHITE_NOISE.key()),
        idToSample(AudioSamples.FAN_SOUND.key())
    )

    val stayAsleepSamples = listOf(
        idToSample(AudioSamples.BROWN_NOISE.key()),
        idToSample(AudioSamples.PINK_NOISE.key()),
        idToSample(AudioSamples.WHITE_NOISE.key()),
        idToSample(AudioSamples.FAN_SOUND.key())
    )

    val focusSamples = listOf(
        idToSample(AudioSamples.BROWN_NOISE.key()),
        idToSample(AudioSamples.PINK_NOISE.key()),
        idToSample(AudioSamples.WHITE_NOISE.key()),
        idToSample(AudioSamples.FAN_SOUND.key())
    )

    private val _mediaPlayer = MediaPlayer()
    private val _soundPool = SoundPool.Builder().setMaxStreams(1).build()
    private var _soundId: Int? = null
    private var _playing: Boolean = false
    private var _loaded: Boolean = false

    private fun idToSample(id: String) : AudioSample {
        return _idToSampleMap[id]!!
    }

    fun idToSample(id: String?, default: AudioSamples) : AudioSample? {
        if (id == null || !_idToSampleMap.containsKey(id)) {
            return _idToSampleMap[default.key()]
        }
        return _idToSampleMap[id]
    }

    fun loopAudioSample(context: Context, resId: Int) {
        _playing = true
        _soundId = _soundPool.load(context, resId, 1)
        _soundPool.setOnLoadCompleteListener { _, _, _ ->
            _loaded = true
            if (_playing) {
                _soundPool.play(_soundId!!, /*leftVolume=*/1f, /*rightVolume=*/1f, /*priority=*/1,
                    /*loop=*/-1, /*rate=*/1f)
            }
        }
    }

    fun stopLoopAudioSample() {
        if (_playing && _soundId != null) {
            _soundPool.stop(_soundId!!)
            _soundPool.unload(_soundId!!)
            _soundId = null
            _loaded = false
            _playing = false
        }
    }

    fun playAudioSample(context: Context, resId: Int, onComplete: () -> Unit = {}) {
        val mediaPath =
            Uri.parse("android.resource://${context.packageName}/$resId")
        _mediaPlayer.apply {
            reset()
            setDataSource(context, mediaPath)
            prepare()
            setOnCompletionListener { onComplete() }
            start()
        }
    }

    fun stopAudioSample() {
        _mediaPlayer.stop()
        _mediaPlayer.release()
    }
}