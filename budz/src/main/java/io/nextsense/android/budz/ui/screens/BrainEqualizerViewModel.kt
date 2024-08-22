package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.media.AudioManager
import android.os.Handler
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
import io.nextsense.android.base.devices.maui.MauiDevice
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.EarEegChannel
import io.nextsense.android.budz.manager.EarbudsConfigNames
import io.nextsense.android.budz.manager.EarbudsConfigs
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
    val modulationDemoMode: Boolean = true,
    val amplitudeTarget: Int = 2,
    val direction: AlphaDirection = AlphaDirection.UP,
    val activeChannel: EarEegChannel = EarbudsConfigs.getEarbudsConfig(
        EarbudsConfigNames.MAUI_CONFIG.name).channelsConfig[1]!!,
    val activeBand: BandPowerAnalysis.Band = BandPowerAnalysis.Band.ALPHA,
    val leftBandPower: Float? = null,
    val rightBandPower: Float? = null,
    val bandPower: Float? = null,
    val bandPowerSnapshot: Float? = null,
    val modulatingStarted: Boolean = false,
    val modulationSuccess: Boolean = false,
    val modulationDifference: Float? = null
)

@UnstableApi
@HiltViewModel
class BrainEqualizerViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    val airohaDeviceManager: AirohaDeviceManager,
    val signalStateManager: SignalStateManager,
): SignalVisualizationViewModel(context, airohaDeviceManager, signalStateManager) {

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

    fun changeActiveBand(band: BandPowerAnalysis.Band) {
        _uiState.value = _uiState.value.copy(activeBand = band)
    }

    fun changeAmplitudeTarget(amplitude: Int) {
        _uiState.value = _uiState.value.copy(amplitudeTarget = amplitude)
    }

    fun changeDirection(direction: AlphaDirection) {
        _uiState.value = _uiState.value.copy(direction = direction)
    }

    fun changeActiveChannel(activeChannel: EarEegChannel) {
        _uiState.value = _uiState.value.copy(activeChannel = activeChannel, bandPower =
        if (activeChannel == EarEegChannel.ELW_ELC) {
            _uiState.value.leftBandPower
        } else {
            _uiState.value.rightBandPower
        })
    }

    fun getChannels(): List<String> {
        return EarbudsConfigs.getEarbudsConfig(MauiDevice.EARBUD_CONFIG).channelsConfig.values
            .map { it.alias }
    }

    fun startStopModulating() {
        if (_uiState.value.modulatingStarted) {
            _uiState.value = _uiState.value.copy(modulatingStarted = false, bandPowerSnapshot = null,
                modulationSuccess = false, modulationDifference = null)
            _bassEqLevel = 0f
            _trebleEqLevel = 0f
            if (_modulatedVolume) {
                modulateVolume(increase = false)
                applySoundModulation(_bassEqLevel, _trebleEqLevel)
                _modulatedVolume = false
            }

        } else {
            _uiState.value = _uiState.value.copy(modulatingStarted = true,
                bandPowerSnapshot = _uiState.value.bandPower)
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
                        RotatingFileLogger.get().logv(tag, "Slow update time: $runtimeMs")
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
        if (bandPowers.isEmpty()) {
            return
        }

        val gotLeft = bandPowers.containsKey(1)
        val gotRight = bandPowers.containsKey(2)
        if (!gotLeft && !gotRight) {
            return
        }
        var leftBandPower: Float? = null
        var rightBandPower: Float? = null
        var bandPowerValue: Float? = null
        if (gotLeft) {
            leftBandPower = bandPowers[1]?.get(_uiState.value.activeBand)?.toFloat().let {
                it?.times(100) ?: 0F }
            if (uiState.value.activeChannel == EarEegChannel.ELW_ELC) {
                bandPowerValue = leftBandPower
            }
        }
        if (gotRight) {
            rightBandPower = bandPowers[2]?.get(_uiState.value.activeBand)?.toFloat().let {
                it?.times(100) ?: 0F }
            if (uiState.value.activeChannel == EarEegChannel.ERW_ERC) {
                bandPowerValue = rightBandPower
            }
        }

       _uiState.value = _uiState.value.copy(bandPower = bandPowerValue, leftBandPower = leftBandPower,
           rightBandPower = rightBandPower)

        for (channelBandPowers in bandPowers.entries) {
            val channel = if (channelBandPowers.key == 1) "Left" else "Right"

            RotatingFileLogger.get().logd(tag,
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
        }

        if (uiState.value.modulatingStarted) {
            var amplitudeChange = 0F
            if (uiState.value.modulationDemoMode) {
                if (uiState.value.bandPower == null || uiState.value.bandPowerSnapshot == null) {
                    return
                }
                val amplitudeChangeTarget = uiState.value.amplitudeTarget
                if (uiState.value.direction == AlphaDirection.UP) {
                    amplitudeChange = (uiState.value.bandPower!! - (uiState.value.bandPowerSnapshot!! +
                            amplitudeChangeTarget)).coerceAtLeast(0F)
                } else if (uiState.value.direction == AlphaDirection.DOWN) {
                    amplitudeChange = ((uiState.value.bandPowerSnapshot!! - amplitudeChangeTarget) -
                            uiState.value.bandPower!!).coerceAtLeast(0F)
                }
                _bassEqLevel = (amplitudeChange * AirohaDeviceManager.MAX_EQUALIZER_SETTING * 6).
                    coerceAtMost(AirohaDeviceManager.MAX_EQUALIZER_SETTING.toFloat())
                _trebleEqLevel = 0F
            }
            RotatingFileLogger.get().logd(tag, "Bass: $_bassEqLevel Treble: $_trebleEqLevel")

            if (!_modulatedVolume && _bassEqLevel > 0F) {
                modulateVolume()
                _modulatedVolume = true
                _uiState.value = _uiState.value.copy(modulationSuccess = true,
                    modulationDifference =
                    _uiState.value.bandPower!! - _uiState.value.bandPowerSnapshot!!)
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