package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.os.Handler
import android.util.Log
import androidx.lifecycle.ViewModel
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
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.algo.signal.Sampling
import io.nextsense.android.base.devices.maui.MauiDataParser
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AirohaDeviceState
import io.nextsense.android.budz.manager.FFTAudioProcessor
import io.nextsense.android.budz.manager.StreamingState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

data class BrainEqualizerState(
    val connected: Boolean = false,
)

@UnstableApi
@HiltViewModel
class BrainEqualizerViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val airohaDeviceManager: AirohaDeviceManager
): ViewModel() {

    private val tag = BrainEqualizerViewModel::class.simpleName
    private val _shownDuration = 10.seconds
    private val _filterCropDuration = 3.seconds
    private val _totalDataDuration = _shownDuration + _filterCropDuration
    private val _refreshInterval = 100.milliseconds
    private val _chartSamplingRate = 100F
    private val _uiState = MutableStateFlow(BrainEqualizerState())
    private var _stopping = false
    private var _dataRefreshJob: Job? = null
    private lateinit var player: ExoPlayer

    val leftEarChartModelProducer = CartesianChartModelProducer()
    val rightEarChartModelProducer = CartesianChartModelProducer()
    val fftAudioProcessor = FFTAudioProcessor()
    val uiState: StateFlow<BrainEqualizerState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect { deviceState ->
                _uiState.value =
                    BrainEqualizerState(connected = deviceState == AirohaDeviceState.READY ||
                            deviceState == AirohaDeviceState.CONNECTING_BLE ||
                            deviceState == AirohaDeviceState.CONNECTED_BLE
                    )
                when (deviceState) {
                    AirohaDeviceState.READY -> {
                        if (!_stopping) {
                            airohaDeviceManager.startBleStreaming()
                        }
                    }
                    else -> {
                        // Nothing to do
                    }
                }
            }
        }
        viewModelScope.launch(Dispatchers.IO) {
            airohaDeviceManager.streamingState.collect { streamingState ->
                when (streamingState) {
                    StreamingState.STARTED -> {
                        _dataRefreshJob?.cancel()
                        _dataRefreshJob = viewModelScope.launch(Dispatchers.IO) {
                            while (true) {
                                val startTime = System.currentTimeMillis()
                                updateSignalCharts()
                                val runtimeMs = System.currentTimeMillis() - startTime
                                Log.d(tag, "Update time: " +
                                        "${System.currentTimeMillis() - startTime}")
                                delay(Math.max(_refreshInterval.inWholeMilliseconds - runtimeMs, 0))
                            }
                        }
                    }
                    StreamingState.STOPPED -> {
                        Log.i(tag, "Streaming stopped")
                        _dataRefreshJob?.cancel()
                    }
                    else -> {
                        Log.i(tag, "Streaming $streamingState")
                    }
                }
            }
        }
        initPlayer()
    }

    fun startStreaming() {
        _stopping = false
        viewModelScope.launch {
            airohaDeviceManager.startBleStreaming()
        }
    }

    fun stopStreaming() {
        _stopping = true
        viewModelScope.launch {
            _dataRefreshJob?.cancel()
            airohaDeviceManager.stopBleStreaming()
            delay(500L)
        }
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

    private suspend fun updateSignalCharts() {
        // Get the data for both ears.
        val leftEarData = airohaDeviceManager.getChannelData(
            localSessionId=null,
            channelName=MauiDataParser.CHANNEL_LEFT.toString(),
            durationMillis=_totalDataDuration.inWholeMilliseconds.toInt(),
            fromDatabase=false)
        val rightEarData = airohaDeviceManager.getChannelData(
            localSessionId=null,
            channelName=MauiDataParser.CHANNEL_RIGHT.toString(),
            durationMillis=_totalDataDuration.inWholeMilliseconds.toInt(),
            fromDatabase=false)
        val gotRightEarData = rightEarData != null && rightEarData.size >=
                _filterCropDuration.inWholeMilliseconds + 100
        val gotLeftEarData = leftEarData != null && leftEarData.size >=
                _filterCropDuration.inWholeMilliseconds + 100
        if (!gotLeftEarData && !gotRightEarData) {
            return
        }

        // Update the charts.
        if (gotLeftEarData) {
            val leftEarDataPrepared = prepareData(leftEarData!!)
            leftEarChartModelProducer.runTransaction {
                lineSeries { series(leftEarDataPrepared) }
            }
        }
        if (gotRightEarData) {
            val rightEarDataPrepared = prepareData(rightEarData!!)
            rightEarChartModelProducer.runTransaction {
                lineSeries { series(rightEarDataPrepared) }
            }
        }
    }

    private fun prepareData(data: List<Float>): List<Double> {
        val doubleData = data.map { it.toDouble() }.toDoubleArray()
        val doubleArrayData = Sampling.resample(doubleData, 1000F, 100, _chartSamplingRate)
        // val doubleArrayData = Sampling.resamplePoly(doubleData, _chartSamplingRate, 1000F)
        return doubleArrayData.toList().subList(
            (_filterCropDuration.inWholeMilliseconds / 10).toInt(), doubleArrayData.size)
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