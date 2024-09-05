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
        GREEN_NOISE,
        PINK_NOISE,
        WHITE_NOISE,
        RAIN,
        WAVES,
        WIND,
        DEEP_SLEEP,
        FAN_SOUND;

        fun key() = name.lowercase()
    }

    private val _idToSampleMap = mapOf(
        AudioSamples.BROWN_NOISE.key() to
                AudioSample(AudioSamples.BROWN_NOISE.key(),5, "Brown Noise", R.raw.brown_noise_medium),
        AudioSamples.GREEN_NOISE.key() to
                AudioSample(AudioSamples.GREEN_NOISE.key(), 4, "Green Noise", R.raw.green_noise_medium),
        AudioSamples.PINK_NOISE.key() to
                AudioSample(AudioSamples.PINK_NOISE.key(), 2, "Pink Noise", R.raw.pink_noise_medium),
        AudioSamples.WHITE_NOISE.key() to
                AudioSample(AudioSamples.WHITE_NOISE.key(), 3, "White Noise", R.raw.white_noise_medium),
        AudioSamples.RAIN.key() to
                AudioSample(AudioSamples.RAIN.key(), 6, "Rain", R.raw.natural_rain_medium),
        AudioSamples.WAVES.key() to
                AudioSample(AudioSamples.WAVES.key(), 8, "Waves", R.raw.natural_waves_medium),
        AudioSamples.WIND.key() to
                AudioSample(AudioSamples.WIND.key(), 7, "Wind", R.raw.natural_wind_medium),
        AudioSamples.FAN_SOUND.key() to
                AudioSample(AudioSamples.FAN_SOUND.key(), 1, "Fan Sound", R.raw.fan_sound),
        AudioSamples.DEEP_SLEEP.key() to
                AudioSample(AudioSamples.DEEP_SLEEP.key(), 0, "Deep Sleep", R.raw.deep_sleep)
    )

    private val _colorSamples = AudioGroup(name = "Colors", index = 0, samples = listOf(
        idToSample(AudioSamples.GREEN_NOISE.key()),
        idToSample(AudioSamples.BROWN_NOISE.key()),
        idToSample(AudioSamples.PINK_NOISE.key()),
        idToSample(AudioSamples.WHITE_NOISE.key())).sortedBy { it.index },
    )

    private val _natureSamples = AudioGroup(name = "Nature", index = 1,
        samples = listOf(idToSample(AudioSamples.RAIN.key()),
            idToSample(AudioSamples.WAVES.key()),
            idToSample(AudioSamples.WIND.key())).sortedBy { it.index }
    )

    private val _otherSamples = AudioGroup(name = "Other", index = 1,
        samples = listOf(idToSample(AudioSamples.FAN_SOUND.key()),
            idToSample(AudioSamples.DEEP_SLEEP.key())).sortedBy { it.index }
    )

    private val _fallAsleepSamples = listOf(
        _colorSamples,
        _natureSamples,
        _otherSamples,
    ).sortedBy { it.index }

    private val _stayAsleepSamples = listOf(
        _colorSamples,
        _natureSamples,
        _otherSamples,
    ).sortedBy { it.index }

    private val _focusSamples = listOf(
        _colorSamples,
        _natureSamples,
        _otherSamples,
    ).sortedBy { it.index }

    val audioSamples: Map<AudioSampleType, List<AudioGroup>> = mapOf(
        AudioSampleType.FALL_ASLEEP to _fallAsleepSamples,
        AudioSampleType.FALL_ASLEEP_TIMED_SLEEP to _fallAsleepSamples,
        AudioSampleType.STAY_ASLEEP to _stayAsleepSamples,
        AudioSampleType.STAY_ASLEEP_TIMED_SLEEP to _stayAsleepSamples,
        AudioSampleType.FOCUS to _focusSamples
    )

    val defaultAudioSamples: Map<AudioSampleType, AudioSamples> = mapOf(
        AudioSampleType.FALL_ASLEEP to AudioSamples.DEEP_SLEEP,
        AudioSampleType.FALL_ASLEEP_TIMED_SLEEP to AudioSamples.DEEP_SLEEP,
        AudioSampleType.STAY_ASLEEP to AudioSamples.DEEP_SLEEP,
        AudioSampleType.STAY_ASLEEP_TIMED_SLEEP to AudioSamples.DEEP_SLEEP,
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
        if (_mediaPlayer.isPlaying) {
            _mediaPlayer.stop()
        }
    }
}