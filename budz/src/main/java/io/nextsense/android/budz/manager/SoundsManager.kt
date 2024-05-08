package io.nextsense.android.budz.manager

import android.content.Context
import android.media.MediaPlayer
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
        fun sample() = idToSampleMap[key()]!!
    }

    val idToSampleMap = mapOf(
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
        AudioSamples.BROWN_NOISE.sample(),
        AudioSamples.PINK_NOISE.sample(),
        AudioSamples.WHITE_NOISE.sample(),
        AudioSamples.FAN_SOUND.sample()
    )

    val stayAsleepSamples = listOf(
        AudioSamples.BROWN_NOISE.sample(),
        AudioSamples.PINK_NOISE.sample(),
        AudioSamples.WHITE_NOISE.sample(),
        AudioSamples.FAN_SOUND.sample()
    )

    val focusSamples = listOf(
        AudioSamples.BROWN_NOISE.sample(),
        AudioSamples.PINK_NOISE.sample(),
        AudioSamples.WHITE_NOISE.sample(),
        AudioSamples.FAN_SOUND.sample()
    )

    private val mediaPlayer = MediaPlayer()

    fun playAudioSample(context: Context, resId: Int, onComplete: () -> Unit = {}) {
        val mediaPath =
            Uri.parse("android.resource://${context.packageName}/$resId")
        mediaPlayer.apply {
            reset()
            setDataSource(context, mediaPath)
            prepare()
            setOnCompletionListener { onComplete() }
            start()
        }
    }

    fun stopAudioSample() {
        mediaPlayer.stop()
    }
}