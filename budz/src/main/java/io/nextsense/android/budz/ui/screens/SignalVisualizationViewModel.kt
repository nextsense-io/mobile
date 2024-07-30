package io.nextsense.android.budz.ui.screens

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.data.lineSeries
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.algo.signal.Filters
import io.nextsense.android.algo.signal.Sampling
import io.nextsense.android.algo.signal.WaveletArtifactRejection
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

/**
 * Holds the state for signal visualization, including connectivity and filtering status.
 */
data class SignalVisualizationState(
    val connected: Boolean = false,
    val filtered: Boolean = true
)

/**
 * ViewModel for handling signal visualization for left and right ear data streaming from Airoha devices.
 */
@HiltViewModel
open class SignalVisualizationViewModel @Inject constructor(
    private val airohaDeviceManager: AirohaDeviceManager
): ViewModel() {
    private val tag = "SignalVisualizationViewModel"
    private val _shownDuration = 10.seconds
    private val _filterCropDuration = 5.seconds
    private val _totalDataDuration = _shownDuration + _filterCropDuration
    private val _refreshInterval = 100.milliseconds
    private val _chartSamplingRate = 100F
    private val _uiState = MutableStateFlow(SignalVisualizationState())
    private var dataRefreshJob: Job? = null
    private var _stopping = false

    val leftEarChartModelProducer = CartesianChartModelProducer()
    val rightEarChartModelProducer = CartesianChartModelProducer()
    val signalUiState: StateFlow<SignalVisualizationState> = _uiState.asStateFlow()

    init {
        // Collects the state of the device and updates the UI state accordingly.
        viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect { deviceState ->
                _uiState.value =
                    SignalVisualizationState(connected = deviceState == AirohaDeviceState.READY ||
                            deviceState == AirohaDeviceState.CONNECTING_BLE ||
                            deviceState == AirohaDeviceState.CONNECTED_BLE)
                when (deviceState) {
                    AirohaDeviceState.READY -> {
                        if (!_stopping) {
                            airohaDeviceManager.startBleStreaming()
                        }
                    }
                    else -> {
                        // Handle other states if necessary
                    }
                }
            }
        }

        // Handles the streaming state changes and updates the charts accordingly.
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
                                Log.d(tag, "Update time: $runtimeMs ms")
                                delay(Math.max(_refreshInterval.inWholeMilliseconds - runtimeMs, 0))
                            }
                        }
                    }
                    StreamingState.STOPPED -> {
                        Log.i(tag, "Streaming stopped")
                        dataRefreshJob?.cancel()
                    }
                    else -> {
                        // Log other streaming states if necessary
                    }
                }
            }
        }
    }

    /**
     * Starts the BLE streaming for signal visualization.
     */
    fun startStreaming() {
        _stopping = false
        viewModelScope.launch {
            airohaDeviceManager.startBleStreaming()
        }
    }

    /**
     * Stops the BLE streaming and cleans up resources.
     */
    fun stopStreaming() {
        _stopping = true
        viewModelScope.launch {
            dataRefreshJob?.cancel()
            airohaDeviceManager.stopBleStreaming()
            delay(500L)
        }
    }

    /**
     * Toggles the filtering state of the signal visualization.
     */
    fun setFiltered(filtered: Boolean) {
        _uiState.value = _uiState.value.copy(filtered = filtered)
    }

    /**
     * Updates the charts with new data from the BLE device.
     */
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
        if (leftEarData != null && rightEarData != null) {
            // Update the charts if data is available for both ears.
            updateChart(leftEarChartModelProducer, leftEarData)
            updateChart(rightEarChartModelProducer, rightEarData)
        }
    }

    /**
     * Renders the data onto the specified chart producer.
     */
    private suspend fun updateChart(producer: CartesianChartModelProducer, data: List<Float>) {
        val preparedData = prepareData(data)
        producer.runTransaction {
            lineSeries { series(preparedData) }
        }
    }

    /**
     * Prepares the data for visualization, applying filtering and resampling.
     */
    private fun prepareData(data: List<Float>): List<Double> {
        if (data.size < 3) {  // Ensure there's enough data to process
            Log.e(tag, "Insufficient data for operations: Size=${data.size}")
            return emptyList()  // Return an empty list or handle as appropriate
        }

        // Convert List<Float> to DoubleArray for processing
        var doubleData = data.map { it.toDouble() }.toDoubleArray()

        // Apply wavelet denoising if filtering is enabled
        if (_uiState.value.filtered) {
            doubleData = applyWaveletDenoising(doubleData)
            doubleData = Filters.applyBandStop(doubleData, /*samplingRate=*/1000F,
                /*order=*/5, /*centerFrequency=*/60F, /*widthFrequency=*/2F)
            doubleData = Filters.applyBandPass(doubleData, /*samplingRate=*/1000F,
                /*order=*/5, /*lowCutoff=*/.5F, /*highCutoff=*/45F)
        }

        // Ensure the length of doubleData is a power of two
        var validLength = 1
        while (validLength <= doubleData.size) validLength *= 2
        validLength /= 2  // validLength is now the largest power of 2 less than or equal to doubleData.size

        if (validLength < 2) {  // Check if the valid length is less than the minimum required size for further processing
            Log.e(tag, "Data length is not a valid power of two or is too small after processing: Length=$validLength")
            return emptyList()
        }

        // Resample the data to the chart sampling rate for performance using the valid length
        val doubleArrayData = Sampling.resample(doubleData.copyOfRange(0, validLength), 1000F, 100, _chartSamplingRate)
        return doubleArrayData.toList().subList(
            (_filterCropDuration.inWholeMilliseconds / 10).toInt(), doubleArrayData.size)
    }


    /**
     * Applies wavelet denoising to the raw data.
     */
    private fun applyWaveletDenoising(dataArray: DoubleArray): DoubleArray {
        return try {
            WaveletArtifactRejection.applyWaveletArtifactRejection(dataArray)
        } catch (e: Exception) {
            Log.e(tag, "Wavelet denoising failed: ${e.localizedMessage}")
            dataArray // Return original data if the process fails
        }
    }
}
