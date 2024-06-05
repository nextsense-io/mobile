package io.nextsense.android.budz.manager

import android.content.Context
import android.media.MediaPlayer
import android.media.SoundPool
import android.net.Uri
import io.nextsense.android.budz.R

enum class AudioSampleType {
    FALL_ASLEEP,
    FALL_ASLEEP_TIMED_SLEEP,
    STAY_ASLEEP,
    STAY_ASLEEP_TIMED_SLEEP,
    FOCUS
}

data class AudioSample (
    val id: String,  // Unique identifier used in the database
    val index: Int,  // Index of the order in which the sample should be displayed
    val name: String,  // Displayed name in the UI
    val resId: Int  // Raw resource ID of the audio file
)

data class AudioGroup(
    val index: Int,  // Index of the order in which the group should be displayed
    val name: String,  // Name of the group displayed over the audio samples
    val samples: List<AudioSample>
)

object SoundsManager {

    enum class AudioSamples {
        BROWN_NOISE,
        PINK_NOISE,
        WHITE_NOISE,
        FAN_SOUND;

        fun key() = name.lowercase()
    }

    private val _idToSampleMap = mapOf(
        AudioSamples.BROWN_NOISE.key() to
                AudioSample(AudioSamples.BROWN_NOISE.key(),0, "Brown Noise", R.raw.brown_noise),
        AudioSamples.PINK_NOISE.key() to
                AudioSample(AudioSamples.PINK_NOISE.key(), 2, "Pink Noise", R.raw.pink_noise),
        AudioSamples.WHITE_NOISE.key() to
                AudioSample(AudioSamples.WHITE_NOISE.key(), 1, "White Noise", R.raw.white_noise),
        AudioSamples.FAN_SOUND.key() to
                AudioSample(AudioSamples.FAN_SOUND.key(), 3, "Fan Sound", R.raw.fan_sound)
    )

    private val _steadyNoiseSamples = AudioGroup(name = "Steady Noise", index = 0, samples = listOf(
        idToSample(AudioSamples.BROWN_NOISE.key()),
        idToSample(AudioSamples.PINK_NOISE.key()),
        idToSample(AudioSamples.WHITE_NOISE.key())).sortedBy { it.index },
    )

    private val _mechanicalNoiseSamples = AudioGroup(name = "Mechanical Noise", index = 1, samples = listOf(
        idToSample(AudioSamples.FAN_SOUND.key())).sortedBy { it.index }
    )

    private val _fallAsleepSamples = listOf(
        _steadyNoiseSamples,
        _mechanicalNoiseSamples,
    ).sortedBy { it.index }

    private val _stayAsleepSamples = listOf(
        _steadyNoiseSamples,
        _mechanicalNoiseSamples,
    ).sortedBy { it.index }

    private val _focusSamples = listOf(
        _steadyNoiseSamples,
        _mechanicalNoiseSamples,
    ).sortedBy { it.index }

    val audioSamples: Map<AudioSampleType, List<AudioGroup>> = mapOf(
        AudioSampleType.FALL_ASLEEP to _fallAsleepSamples,
        AudioSampleType.FALL_ASLEEP_TIMED_SLEEP to _fallAsleepSamples,
        AudioSampleType.STAY_ASLEEP to _stayAsleepSamples,
        AudioSampleType.STAY_ASLEEP_TIMED_SLEEP to _stayAsleepSamples,
        AudioSampleType.FOCUS to _focusSamples
    )

    val defaultAudioSamples: Map<AudioSampleType, AudioSamples> = mapOf(
        AudioSampleType.FALL_ASLEEP to AudioSamples.FAN_SOUND,
        AudioSampleType.FALL_ASLEEP_TIMED_SLEEP to AudioSamples.FAN_SOUND,
        AudioSampleType.STAY_ASLEEP to AudioSamples.BROWN_NOISE,
        AudioSampleType.STAY_ASLEEP_TIMED_SLEEP to AudioSamples.BROWN_NOISE,
        AudioSampleType.FOCUS to AudioSamples.WHITE_NOISE
    )

    private val _mediaPlayer = MediaPlayer()
    private val _soundPool = SoundPool.Builder().setMaxStreams(1).build()
    private var _soundId: Int? = null
    private var _playing: Boolean = false
    private var _paused: Boolean = false
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

    fun pauseAudioSample() {
        if (_playing && _soundId != null) {
            _soundPool.pause(_soundId!!)
            _paused = true
            _playing = false
        }
    }

    fun resumeAudioSample() {
        if (_paused && _loaded && _soundId != null) {
            _soundPool.resume(_soundId!!)
            _playing = true
            _paused = false
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
    }
}