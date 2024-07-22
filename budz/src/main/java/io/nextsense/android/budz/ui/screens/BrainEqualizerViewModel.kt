package io.nextsense.android.budz.ui.screens

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.algo.signal.Sampling
import io.nextsense.android.base.devices.maui.MauiDataParser
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AirohaDeviceState
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
@HiltViewModel
class BrainEqualizerViewModel @Inject constructor(
    private val airohaDeviceManager: AirohaDeviceManager
): ViewModel() {

    private val tag = BrainEqualizerViewModel::class.simpleName
    private val _shownDuration = 10.seconds
    private val _filterCropDuration = 2.seconds
    private val _totalDataDuration = _shownDuration + _filterCropDuration
    private val _refreshInterval = 100.milliseconds
    private val _chartSamplingRate = 100F
    private val _uiState = MutableStateFlow(BrainEqualizerState())
    private var dataRefreshJob: Job? = null

    val leftEarChartModelProducer = CartesianChartModelProducer()
    val rightEarChartModelProducer = CartesianChartModelProducer()
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
                        airohaDeviceManager.startBleStreaming()
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
                        dataRefreshJob?.cancel()
                        dataRefreshJob = viewModelScope.launch(Dispatchers.IO) {
                            while (true) {
                                val startTime = System.currentTimeMillis()
                                val leftEarData = airohaDeviceManager.getChannelData(
                                    localSessionId=null,
                                    channelName= MauiDataParser.CHANNEL_LEFT.toString(),
                                    durationMillis=_totalDataDuration.inWholeMilliseconds.toInt(),
                                    fromDatabase=false)
                                if (leftEarData == null || leftEarData.size < 2100) {
                                    continue
                                }
                                Log.d("CheckConnectionViewModel", "Before prepare: " +
                                        "${System.currentTimeMillis() - startTime}")
                                val preparedData = prepareData(leftEarData)
                                Log.d("CheckConnectionViewModel", "Before chart: " +
                                        "${System.currentTimeMillis() - startTime}")
                                leftEarChartModelProducer.runTransaction {
                                    lineSeries { series(preparedData) }
                                }
                                Log.d("CheckConnectionViewModel", "After chart: " +
                                        "${System.currentTimeMillis() - startTime}")
                                val rightEarData = airohaDeviceManager.getChannelData(
                                    localSessionId=null,
                                    channelName= MauiDataParser.CHANNEL_RIGHT.toString(),
                                    durationMillis=_totalDataDuration.inWholeMilliseconds.toInt(),
                                    fromDatabase=false)
                                if (rightEarData == null || rightEarData.size < 2100) {
                                    continue
                                }
                                rightEarChartModelProducer.runTransaction {
                                    lineSeries { series(prepareData(rightEarData)) }
                                }
                                val runtimeMs = System.currentTimeMillis() - startTime
                                Log.d("CheckConnectionViewModel", "Update time: " +
                                        "${System.currentTimeMillis() - startTime}")
                                delay(Math.max(_refreshInterval.inWholeMilliseconds - runtimeMs, 0))
                            }
                        }
                    }
                    else -> {
                        Log.i(tag, "Streaming stopped")
                        dataRefreshJob?.cancel()
                    }
                }
            }
        }
    }

    fun startStreaming() {
        viewModelScope.launch {
            airohaDeviceManager.startBleStreaming()
        }
    }

    fun stopStreaming() {
        viewModelScope.launch {
            airohaDeviceManager.stopBleStreaming()
        }
    }

    private fun prepareData(data: List<Float>): List<Double> {
        val doubleData = data.map { it.toDouble() }.toDoubleArray()
        val doubleArrayData = Sampling.resample(doubleData, 1000F, 100, _chartSamplingRate)
        return doubleArrayData.toList().subList(200, doubleArrayData.size)
    }
}