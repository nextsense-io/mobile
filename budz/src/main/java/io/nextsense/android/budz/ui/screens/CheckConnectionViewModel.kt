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

data class CheckConnectionState(
    val connected: Boolean = false,
    val minY: Int = 0,
    val maxY: Int = 0
)

@HiltViewModel
class CheckConnectionViewModel @Inject constructor(
    private val airohaDeviceManager: AirohaDeviceManager
): ViewModel() {
    private val tag = CheckConnectionViewModel::class.simpleName
    private val _shownDuration = 10.seconds
    private val _filterCropDuration = 2.seconds
    private val _totalDataDuration = _shownDuration + _filterCropDuration
    private val _refreshInterval = 100.milliseconds
    private val _chartSamplingRate = 100F
    private val _uiState = MutableStateFlow(CheckConnectionState())
    private var dataRefreshJob: Job? = null

    val leftEarChartModelProducer = CartesianChartModelProducer()
    val rightEarChartModelProducer = CartesianChartModelProducer()
    val uiState: StateFlow<CheckConnectionState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect { deviceState ->
                _uiState.value =
                    CheckConnectionState(connected = deviceState == AirohaDeviceState.READY ||
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
                                updateSignalCharts()
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

    private suspend fun updateSignalCharts() {
        val startTime = System.currentTimeMillis()

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
        val gotRightEarData = rightEarData != null && rightEarData.size >= 2100
        val gotLeftEarData = leftEarData != null && leftEarData.size >= 2100
        if (!gotLeftEarData && !gotRightEarData) {
            return
        }

        val leftEarDataPrepared = if (gotLeftEarData) prepareData(leftEarData!!) else emptyList()
        val rightEarDataPrepared = if (gotRightEarData) prepareData(rightEarData!!) else emptyList()

        // Update Y scale for the charts.
        if (gotLeftEarData && gotRightEarData) {
            val (leftMinY, lefMaxY) = getDataBounds(leftEarDataPrepared)
            val (rightMinY, rightMaxY) = getDataBounds(rightEarDataPrepared)
            _uiState.value = CheckConnectionState(
                connected = true,
                minY = leftMinY.coerceAtMost(rightMinY),
                maxY = lefMaxY.coerceAtLeast(rightMaxY)
            )
        } else if (gotLeftEarData) {
            val (leftMinY, lefMaxY) = getDataBounds(leftEarDataPrepared)
            _uiState.value = CheckConnectionState(
                connected = true,
                minY = leftMinY,
                maxY = lefMaxY
            )
        } else {
            val (rightMinY, rightMaxY) = getDataBounds(rightEarDataPrepared)
            _uiState.value = CheckConnectionState(
                connected = true,
                minY = rightMinY,
                maxY = rightMaxY
            )
        }

        // Update the charts.
        if (gotLeftEarData) {
            Log.d("CheckConnectionViewModel", "Before chart: " +
                    "${System.currentTimeMillis() - startTime}")
            leftEarChartModelProducer.runTransaction {
                lineSeries { series(leftEarDataPrepared) }
            }
            Log.d("CheckConnectionViewModel", "After chart: " +
                    "${System.currentTimeMillis() - startTime}")
        }
        if (gotRightEarData) {
            rightEarChartModelProducer.runTransaction {
                lineSeries { series(rightEarDataPrepared) }
            }
        }
    }

    private fun prepareData(data: List<Float>): List<Double> {
        val doubleData = data.map { it.toDouble() }.toDoubleArray()
        val doubleArrayData = Sampling.resample(doubleData, 1000F, 100, _chartSamplingRate)
        // val doubleArrayData = Sampling.resamplePoly(doubleData, _chartSamplingRate, 1000F)
        return doubleArrayData.toList().subList(200, doubleArrayData.size)
    }

    private fun getDataBounds(data: List<Double>): Pair<Int, Int> {
        return data.minOrNull()!!.toInt() to data.maxOrNull()!!.toInt() + 1
    }
}