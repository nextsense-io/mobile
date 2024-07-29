package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.os.Handler
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSourceFactory
import androidx.media3.datasource.RawResourceDataSource
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.Renderer
import androidx.media3.exoplayer.audio.AudioRendererEventListener
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.MediaCodecAudioRenderer
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.FFTAudioProcessor
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

data class BrainEqualizerState(
    val connected: Boolean = false,
)

@UnstableApi
@HiltViewModel
class BrainEqualizerViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    val airohaDeviceManager: AirohaDeviceManager
): SignalVisualizationViewModel(airohaDeviceManager) {

    private val tag = BrainEqualizerViewModel::class.simpleName
    private val _uiState = MutableStateFlow(BrainEqualizerState())
    private lateinit var player: ExoPlayer

    val fftAudioProcessor = FFTAudioProcessor()
    val uiState: StateFlow<BrainEqualizerState> = _uiState.asStateFlow()

    init {
        initPlayer()
    }

    fun startPlayer() {
        player.playWhenReady = true
    }

    fun pausePlayer() {
        player.playWhenReady = false
    }

    fun stopPlayer() {
        player.stop()
        player.release()
    }

    private fun initPlayer() {
        // We need to create a renderers factory to inject our own audio processor at the end of the
        // list.
        val renderersFactory = object : DefaultRenderersFactory(context) {

            override fun buildAudioRenderers(
                context: Context,
                extensionRendererMode: Int,
                mediaCodecSelector: MediaCodecSelector,
                enableDecoderFallback: Boolean,
                audioSink: AudioSink,
                eventHandler: Handler,
                eventListener: AudioRendererEventListener,
                out: ArrayList<Renderer>
            ) {
                out.add(
                    MediaCodecAudioRenderer(
                        context,
                        mediaCodecSelector,
                        enableDecoderFallback,
                        eventHandler,
                        eventListener,
                        DefaultAudioSink.Builder(context)
                            .setAudioProcessors(arrayOf(fftAudioProcessor)).build()
                    )
                )

                super.buildAudioRenderers(
                    context,
                    extensionRendererMode,
                    mediaCodecSelector,
                    enableDecoderFallback,
                    audioSink,
                    eventHandler,
                    eventListener,
                    out
                )
            }
        }
        player = ExoPlayer.Builder(context, renderersFactory).build()
        player.repeatMode = ExoPlayer.REPEAT_MODE_ALL

        // Online radio:
        // val uri = Uri.parse("https://listen.livestreamingservice.com/181-xsoundtrax_128k.mp3")
        val uri = RawResourceDataSource.buildRawResourceUri(R.raw.fan_sound)
        // 1 kHz test sound:
        // val uri = Uri.parse("https://www.mediacollege.com/audio/tone/files/1kHz_44100Hz_16bit_05sec.mp3")
        // 10 kHz test sound:
        // val uri = Uri.parse("https://www.mediacollege.com/audio/tone/files/10kHz_44100Hz_16bit_05sec.mp3")
        // Sweep from 20 to 20 kHz
        // val uri = Uri.parse("https://www.churchsoundcheck.com/CSC_sweep_20-20k.wav")
        val mediaSource = ProgressiveMediaSource.Factory(
            DefaultDataSourceFactory(context, "ExoVisualizer")
        ).createMediaSource(MediaItem.Builder().setUri(uri).build())
        player.playWhenReady = true
        player.setMediaSource(mediaSource)
        player.prepare()
    }
}