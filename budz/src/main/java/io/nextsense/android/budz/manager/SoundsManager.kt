package io.nextsense.android.budz.manager

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import io.nextsense.android.budz.R

data class AudioSample(
    val name: String,
    val resId: Int
)

object SoundsManager {

    val fallAsleepSamples = listOf(
        AudioSample("Brown Noise", R.raw.brown_noise),
        AudioSample("Pink Noise", R.raw.pink_noise),
        AudioSample("White Noise", R.raw.white_noise),
        AudioSample("Fan Sound", R.raw.fan_sound)
    )

    val stayAsleepSamples = listOf(
        AudioSample("Brown Noise", R.raw.brown_noise),
        AudioSample("Pink Noise", R.raw.pink_noise),
        AudioSample("White Noise", R.raw.white_noise),
        AudioSample("Fan Sound", R.raw.fan_sound)
    )

    val focusSamples = listOf(
        AudioSample("Brown Noise", R.raw.brown_noise),
        AudioSample("Pink Noise", R.raw.pink_noise),
        AudioSample("White Noise", R.raw.white_noise),
        AudioSample("Fan Sound", R.raw.fan_sound)
    )

    private val mediaPlayer = MediaPlayer()

    fun playAudioSample(context: Context, resId: Int) {
        val mediaPath =
            Uri.parse("android.resource://${context.packageName}/$resId")
        mediaPlayer.apply {
            reset()
            setDataSource(context, mediaPath)
            prepare()
            start()
        }
    }

    fun stopAudioSample() {
        mediaPlayer.stop()
    }
}