package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.media.AudioManager
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
import io.nextsense.android.budz.manager.SignalStateManager
import io.nextsense.android.budz.manager.StreamingState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.time.Duration.Companion.seconds

enum class AlphaDirection(val direction: String) {
    UP("Up"), DOWN("Down");

    companion object {
        fun fromString(value: String): AlphaDirection {
            return values().first { it.name == value }
        }
    }

    override fun toString(): String {
        return name
    }
}

data class BrainEqualizerState(
    val connected: Boolean = false,
    val alphaModulationDemoMode: Boolean = true,
    val alphaAmplitudeTarget: Int = 2,
    val alphaDirection: AlphaDirection = AlphaDirection.UP,
    val leftAlpha: Float? = null,
    val rightAlpha: Float? = null,
    val alpha: Float? = null,
    val alphaSnapshot: Float? = null,
    val modulatingStarted: Boolean = false,
    val alphaModulationSuccess: Boolean = false,
    val alphaModulationDifference: Float? = null
)

private const val alphaBetaRatioMidPoint = 1F
private const val alphaStepSize = 2F

@UnstableApi
@HiltViewModel
class BrainEqualizerViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    val airohaDeviceManager: AirohaDeviceManager,
    val signalStateManager: SignalStateManager,
): SignalVisualizationViewModel(airohaDeviceManager, signalStateManager) {

    private val tag = BrainEqualizerViewModel::class.simpleName
    private val _audioManager: AudioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val _maxMusicVolume = _audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    private val _uiState = MutableStateFlow(BrainEqualizerState())
    private val _soundModulationInterval = 5.seconds
    private var _soundModulationJob: Job? = null
    private lateinit var _player: ExoPlayer
    private var _bassEqLevel = 0F
    private var _trebleEqLevel = 0F
    private var _modulatedVolume = false

    val uiState: StateFlow<BrainEqualizerState> = _uiState.asStateFlow()
    val fftAudioProcessor = FFTAudioProcessor()

    fun changeAmplitudeTarget(amplitude: Int) {
        _uiState.value = _uiState.value.copy(alphaAmplitudeTarget = amplitude)
    }

    fun changeAlphaDirection(direction: AlphaDirection) {
        _uiState.value = _uiState.value.copy(alphaDirection = direction)
    }

    fun startStopModulating() {
        if (_uiState.value.modulatingStarted) {
            _uiState.value = _uiState.value.copy(modulatingStarted = false, alphaSnapshot = null,
                alphaModulationSuccess = false, alphaModulationDifference = null)
            _bassEqLevel = 0f
            _trebleEqLevel = 0f
            if (_modulatedVolume) {
                modulateVolume(increase = false)
                applySoundModulation(_bassEqLevel, _trebleEqLevel)
                _modulatedVolume = false
            }

        } else {
            _uiState.value = _uiState.value.copy(modulatingStarted = true,
                alphaSnapshot = _uiState.value.alpha)
        }
    }

    fun startPlayer() {
        initPlayer()
    }

    fun pausePlayer() {
        _player.playWhenReady = false
    }

    fun resumePlayer() {
        _player.playWhenReady = true
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
                    if (runtimeMs > refreshInterval.inWholeMilliseconds) {
                        Log.d(tag, "Slow update time: $runtimeMs")
                    }
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

    private fun applySoundModulation(bassLevel: Float, trebleLevel: Float) {
        val eqArray = floatArrayOf(
            bassLevel, bassLevel,  // Bass is 300 hertz and lower.
            0f, 0f, 0f, 0f, 0f,  // Mid is 300 hertz to 4 khz
            _trebleEqLevel, _trebleEqLevel, _trebleEqLevel  // Treble is 4 khz and higher.
        )
        fftAudioProcessor.setEqualizerValues(eqArray)
        airohaDeviceManager.changeEqualizer(eqArray)
    }

    private fun modulateVolume(increase: Boolean = true) {
        val currentVolume = _audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val targetVolume = if (increase) {
            currentVolume + _maxMusicVolume / 4
        } else {
            currentVolume - _maxMusicVolume / 4
        }
        _audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
    }

    private fun updateSoundModulation() {
        if (airohaDeviceManager.streamingState.value != StreamingState.STARTED) {
            return
        }
        val bandPowers = signalStateManager.getBandPowers(listOf(BandPowerAnalysis.Band.DELTA,
            BandPowerAnalysis.Band.THETA, BandPowerAnalysis.Band.ALPHA, BandPowerAnalysis.Band.BETA,
            BandPowerAnalysis.Band.GAMMA))
//        val bandPowers = signalStateManager.getBandPowers(listOf(BandPowerAnalysis.Band.ALPHA,
//            BandPowerAnalysis.Band.BETA))
        if (bandPowers.isEmpty()) {
            return
        }
        var alphaBetaRatio: Double? = null

        val gotLeft = bandPowers.containsKey(1)
        val gotRight = bandPowers.containsKey(2)
        if (!gotLeft && !gotRight) {
            return
        }
        var leftAlpha: Float? = null
        var rightAlpha: Float? = null
        var alphaValue: Float? = null
        if (gotRight) {
            rightAlpha = bandPowers[2]?.get(BandPowerAnalysis.Band.ALPHA)?.toFloat().let {
                it?.times(100) ?: 0F }
            alphaValue = rightAlpha
        }
        if (gotLeft) {
            leftAlpha = bandPowers[1]?.get(BandPowerAnalysis.Band.ALPHA)?.toFloat().let {
                it?.times(100) ?: 0F }
            if (alphaValue == null) {
                alphaValue = leftAlpha
            }
        }
       _uiState.value = _uiState.value.copy(alpha = alphaValue, leftAlpha = leftAlpha,
           rightAlpha = rightAlpha)

        for (channelBandPowers in bandPowers.entries) {
            val channel = if (channelBandPowers.key == 1) "Left" else "Right"

            Log.d(tag,
                "$channel Delta: ${"%.3f".format(channelBandPowers.value[
                BandPowerAnalysis.Band.DELTA])}" +
                " $channel Theta: ${"%.3f".format(channelBandPowers.value[
                    BandPowerAnalysis.Band.THETA])}" +
                " $channel Alpha: ${"%.3f".format(channelBandPowers.value[
                    BandPowerAnalysis.Band.ALPHA])}" +
                " $channel Beta: ${"%.3f".format(channelBandPowers.value[
                    BandPowerAnalysis.Band.BETA])}" +
                " $channel Gamma: ${"%.3f".format(channelBandPowers.value[
                    BandPowerAnalysis.Band.GAMMA])}"
            )

            if (alphaBetaRatio == null) {
                alphaBetaRatio = channelBandPowers.value[BandPowerAnalysis.Band.ALPHA]!! /
                        channelBandPowers.value[BandPowerAnalysis.Band.BETA]!!
            }
        }

        if (alphaBetaRatio == null) {
            return
        }

        if (uiState.value.modulatingStarted) {
            var amplitudeChange = 0F
            if (uiState.value.alphaModulationDemoMode) {
                if (uiState.value.alpha == null || uiState.value.alphaSnapshot == null) {
                    return
                }
                val amplitudeChangeTarget = uiState.value.alphaAmplitudeTarget
                if (uiState.value.alphaDirection == AlphaDirection.UP) {
                    amplitudeChange = (uiState.value.alpha!! - (uiState.value.alphaSnapshot!! +
                            amplitudeChangeTarget)).coerceAtLeast(0F)
                } else if (uiState.value.alphaDirection == AlphaDirection.DOWN) {
                    amplitudeChange = ((uiState.value.alphaSnapshot!! - amplitudeChangeTarget) -
                            uiState.value.alpha!!).coerceAtLeast(0F)
                }
                _bassEqLevel = (amplitudeChange * AirohaDeviceManager.MAX_EQUALIZER_SETTING * 6).
                    coerceAtMost(AirohaDeviceManager.MAX_EQUALIZER_SETTING.toFloat())
                _trebleEqLevel = 0F
            } else {
                _bassEqLevel = if (alphaBetaRatio >= alphaBetaRatioMidPoint) {
                    (((alphaBetaRatio - alphaBetaRatioMidPoint) * 2).coerceAtMost(1.0) *
                            AirohaDeviceManager.MAX_EQUALIZER_SETTING).toFloat()
                } else {
                    0F
                }
                _trebleEqLevel = if (alphaBetaRatio < alphaBetaRatioMidPoint) {
                    ((alphaBetaRatioMidPoint - alphaBetaRatio).coerceAtMost(1.0) *
                            AirohaDeviceManager.MAX_EQUALIZER_SETTING).toFloat()
                } else {
                    0F
                }
            }
            Log.d(tag, "Bass: $_bassEqLevel Treble: $_trebleEqLevel")

            if (!_modulatedVolume && _bassEqLevel > 0F) {
                modulateVolume()
                _modulatedVolume = true
                _uiState.value = _uiState.value.copy(alphaModulationSuccess = true,
                    alphaModulationDifference =
                    _uiState.value.alpha!! - _uiState.value.alphaSnapshot!!)
            }

            applySoundModulation(_bassEqLevel, _trebleEqLevel)
        }
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
        val uri = RawResourceDataSource.buildRawResourceUri(R.raw.skyline_loop)
        val mediaSource = ProgressiveMediaSource.Factory(
            DefaultDataSourceFactory(context, "ExoVisualizer")
        ).createMediaSource(MediaItem.Builder().setUri(uri).build())
        _player.playWhenReady = true
        _player.setMediaSource(mediaSource)
        _player.prepare()
    }
}