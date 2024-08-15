package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.algo.tflite.SleepWakeModel
import io.nextsense.android.base.devices.maui.MauiDataParser
import io.nextsense.android.base.utils.SleepWakeCsvWriter
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AirohaDeviceState
import io.nextsense.android.budz.manager.SignalStateManager
import io.nextsense.android.budz.manager.StreamingState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds


data class SignalVisualizationState(
    val connected: Boolean = false,
    val filtered: Boolean = true,
    val artifactsRemoval: Boolean = false,
    val powerLineFrequency: Int? = null
)

@HiltViewModel
open class SignalVisualizationViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val airohaDeviceManager: AirohaDeviceManager,
    private val signalStateManager: SignalStateManager
): ViewModel() {
    private val tag = CheckConnectionViewModel::class.simpleName
    private val _shownDuration = 10.seconds
    private val _filterCropDuration = 7.seconds
    // You want at least 17 seconds at 1000 hertz with artifact rejection enabled so it cuts at
    // 16384 samples.
    private val _totalDataDuration = _shownDuration + _filterCropDuration
    private val _chartSamplingRate = 100F
    private val _uiState = MutableStateFlow(SignalVisualizationState())
    private val csvFileNameFormatter: DateTimeFormatter = DateTimeFormatter
        .ofPattern("yyyy-MM-dd_hh-mm-ss")
        .withZone(ZoneId.systemDefault())
    private var _dataRefreshJob: Job? = null
    private var _stopping = false
    private var _eegSamplingRate = 0F
    private var _dataToChartSamplingRateRatio = 1F
    private var _lastSleepWakeInference = 0L
    private var csvWriter: SleepWakeCsvWriter? = null

    protected val refreshInterval = 100.milliseconds
    protected var _updateSignalGraph = true

    val leftEarChartModelProducer = CartesianChartModelProducer()
    val rightEarChartModelProducer = CartesianChartModelProducer()
    val dataPointsSize = (_shownDuration.inWholeSeconds * _chartSamplingRate).toDouble()
    val signalUiState: StateFlow<SignalVisualizationState> = _uiState.asStateFlow()

    init {
        csvWriter = SleepWakeCsvWriter(context)
        val formattedDateTime =
            LocalDateTime.ofInstant(Instant.now(), ZoneOffset.UTC).format(csvFileNameFormatter)
        csvWriter?.initCsvFile("sleep-wake-$formattedDateTime")
        viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect { deviceState ->
                _uiState.value =
                    SignalVisualizationState(connected = deviceState == AirohaDeviceState.READY)
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
                        if (_stopping || _dataRefreshJob != null) {
                            return@collect
                        }
                        _dataToChartSamplingRateRatio = airohaDeviceManager.getEegSamplingRate() /
                                _chartSamplingRate
                        _dataRefreshJob?.cancel()
                        _dataRefreshJob = viewModelScope.launch(Dispatchers.IO) {
                            while (true) {
                                val startTime = System.currentTimeMillis()
                                updateSignalCharts()
                                val runtimeMs = System.currentTimeMillis() - startTime
                                if (runtimeMs > refreshInterval.inWholeMilliseconds) {
                                    Log.d(tag, "Slow update time: $runtimeMs")
                                }
                                delay(Math.max(refreshInterval.inWholeMilliseconds - runtimeMs, 0))
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
    }

    fun setUpdateSignalGraph(updateSignalGraph: Boolean) {
        _updateSignalGraph = updateSignalGraph
    }

    fun closeCsvFile() {
        csvWriter?.closeCsvFile()
    }

    fun startStreaming() {
        _stopping = false
        viewModelScope.launch {
        airohaDeviceManager.startBleStreaming()
            _dataToChartSamplingRateRatio = airohaDeviceManager.getEegSamplingRate() /
                    _chartSamplingRate
            _dataRefreshJob?.cancel()
            _dataRefreshJob = viewModelScope.launch(Dispatchers.IO) {
                while (true) {
                    val startTime = System.currentTimeMillis()
                    if (_updateSignalGraph) {
                        updateSignalCharts()
                    }
                    val runtimeMs = System.currentTimeMillis() - startTime
                    if (runtimeMs > refreshInterval.inWholeMilliseconds) {
                        Log.d(tag, "Slow update time: $runtimeMs")
                    }
                    delay(Math.max(refreshInterval.inWholeMilliseconds - runtimeMs, 0))
                }
            }
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

    fun setFiltered(filtered: Boolean) {
        _uiState.value = _uiState.value.copy(filtered = filtered)
    }

    fun setArtifactsRemoval(artifactsRemoval: Boolean) {
        _uiState.value = _uiState.value.copy(artifactsRemoval = artifactsRemoval)
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
        val minimumDataSize =  _filterCropDuration.inWholeMilliseconds /
                (1000F / _eegSamplingRate) + _chartSamplingRate
        val gotRightEarData = rightEarData != null && rightEarData.size >= minimumDataSize
        val gotLeftEarData = leftEarData != null && leftEarData.size >= minimumDataSize
        if (!gotLeftEarData && !gotRightEarData) {
            return
        }

        // TODO(eric): move somewhere else
        if (System.currentTimeMillis() - _lastSleepWakeInference >
                SleepWakeModel.INPUT_LENGTH.toMillis()) {
            _lastSleepWakeInference = System.currentTimeMillis()
            val leftEarSleeping = if (gotLeftEarData) {
                airohaDeviceManager.runSleepWakeInference(leftEarData!!)
            } else {
                null
            }
            Log.i(tag, "Left Ear Sleeping: $leftEarSleeping")
            val rightEarSleeping = if (gotRightEarData) {
                airohaDeviceManager.runSleepWakeInference(rightEarData!!)
            } else {
                null
            }
            Log.i(tag, "Right Ear Sleeping: $rightEarSleeping")
            csvWriter?.appendData(leftEarSleeping, rightEarSleeping)
        }

        // Update the power line frequency.
        if (_uiState.value.powerLineFrequency == null &&
            signalStateManager.powerLineFrequency != null) {
            _uiState.value = _uiState.value.copy(
                powerLineFrequency = signalStateManager.powerLineFrequency)
        }

        // Update the charts.
        if (gotLeftEarData) {
            val leftEarDataPrepared = prepareData(leftEarData!!)
            if (leftEarDataPrepared.isEmpty()) {
                return
            }
            leftEarChartModelProducer.runTransaction {
                lineSeries { series(leftEarDataPrepared) }
            }
        }
        if (gotRightEarData) {
            val rightEarDataPrepared = prepareData(rightEarData!!)
            if (rightEarDataPrepared.isEmpty()) {
                return
            }
            rightEarChartModelProducer.runTransaction {
                lineSeries { series(rightEarDataPrepared) }
            }
        }
    }

    private fun prepareData(data : List<Float>): List<Double> {
        val preparedData = signalStateManager.prepareVisualizedData(data = data,
            filtered = _uiState.value.filtered, removeArtifacts = _uiState.value.artifactsRemoval,
            targetSamplingRate = _chartSamplingRate)
        val minimumSamples = _filterCropDuration.inWholeMilliseconds / _dataToChartSamplingRateRatio
        if (preparedData.size <= minimumSamples) {
            return listOf()
        }
        val startIndex = (preparedData.size - _shownDuration.inWholeMilliseconds /
                _dataToChartSamplingRateRatio).coerceAtLeast(0F).toInt()
        return preparedData.subList(startIndex, preparedData.size)
    }
}