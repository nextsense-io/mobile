package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.os.Handler
import android.util.Log
import androidx.lifecycle.viewModelScope
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
import io.nextsense.android.algo.signal.BandPowerAnalysis
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.FFTAudioProcessor
import io.nextsense.android.budz.manager.MentalStateManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.time.Duration.Companion.seconds

data class BrainEqualizerState(
    val connected: Boolean = false,
)

private const val alphaBetaRatioMidPoint = 3F

@UnstableApi
@HiltViewModel
class BrainEqualizerViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    val airohaDeviceManager: AirohaDeviceManager,
    val mentalStateManager: MentalStateManager,
): SignalVisualizationViewModel(airohaDeviceManager) {

    private val tag = BrainEqualizerViewModel::class.simpleName
    private val _uiState = MutableStateFlow(BrainEqualizerState())
    private val _soundModulationInterval = 5.seconds
    private var _soundModulationJob: Job? = null
    private lateinit var _player: ExoPlayer
    private var _bassEqLevel = 0F
    private var _trebleEqLevel = 0F

    val uiState: StateFlow<BrainEqualizerState> = _uiState.asStateFlow()
    val fftAudioProcessor = FFTAudioProcessor()

    init {
        initPlayer()
    }

    fun startPlayer() {
        _player.playWhenReady = true
    }

    fun pausePlayer() {
        _player.playWhenReady = false
    }

    fun stopPlayer() {
        _player.stop()
        _player.release()
    }

    fun startModulatingSound() {
        viewModelScope.launch {
            _soundModulationJob?.cancel()
            _soundModulationJob = viewModelScope.launch(Dispatchers.IO) {
                while (true) {
                    val startTime = System.currentTimeMillis()
                    updateSoundModulation()
                    val runtimeMs = System.currentTimeMillis() - startTime
                    Log.d(tag, "Update time: " +
                            "${System.currentTimeMillis() - startTime}")
                    delay(Math.max(_soundModulationInterval.inWholeMilliseconds - runtimeMs, 0))
                }
            }
        }
    }

    fun stopModulatingSound() {
        viewModelScope.launch {
            _soundModulationJob?.cancel()
        }
    }

    private fun updateSoundModulation() {
        val bandPowers = mentalStateManager.getBandPowers(listOf(
            BandPowerAnalysis.Band.ALPHA, BandPowerAnalysis.Band.BETA))
        if (bandPowers.isEmpty()) {
            return
        }
        val alphaBetaRatio = bandPowers[BandPowerAnalysis.Band.ALPHA]!! /
                bandPowers[BandPowerAnalysis.Band.BETA]!!
        Log.d(tag, "Alpha: ${bandPowers[BandPowerAnalysis.Band.ALPHA]} Beta: " +
                "${bandPowers[BandPowerAnalysis.Band.BETA]} Alpha/Beta ratio: $alphaBetaRatio")
        _bassEqLevel = if (alphaBetaRatio >= alphaBetaRatioMidPoint) {
            ((alphaBetaRatio - alphaBetaRatioMidPoint).coerceAtMost(1.0) *
                    AirohaDeviceManager.maxEqualizerSettings).toFloat()
        } else {
            0F
        }
        _trebleEqLevel = if (alphaBetaRatio < 3.0) {
            ((alphaBetaRatioMidPoint - alphaBetaRatio).coerceAtMost(1.0) *
                    AirohaDeviceManager.maxEqualizerSettings).toFloat()
        } else {
            0F
        }
        Log.d(tag, "Bass: $_bassEqLevel Treble: $_trebleEqLevel")
        airohaDeviceManager.changeEqualizer(floatArrayOf(
            _bassEqLevel, _bassEqLevel,  // Bass is 300 hertz and lower.
            0f, 0f, 0f, 0f, 0f,  // Mid is 300 hertz to 4 khz
            _trebleEqLevel, _trebleEqLevel, _trebleEqLevel))  // Treble is 4 khz and higher.

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
        _player = ExoPlayer.Builder(context, renderersFactory).build()
        _player.repeatMode = ExoPlayer.REPEAT_MODE_ALL

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
        _player.playWhenReady = true
        _player.setMediaSource(mediaSource)
        _player.prepare()
    }
}