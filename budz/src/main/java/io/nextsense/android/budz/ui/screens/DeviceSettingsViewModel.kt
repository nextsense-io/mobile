package io.nextsense.android.budz.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.AirohaDeviceManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DeviceSettingsState(
    val message: String,
    val gains: FloatArray = floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f)
)

@HiltViewModel
class DeviceSettingsViewModel @Inject constructor(
        private val deviceManager: AirohaDeviceManager
): ViewModel() {

    private val _uiState = MutableStateFlow(DeviceSettingsState(""))

    val uiState: StateFlow<DeviceSettingsState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            deviceManager.equalizerState.collect { gains ->
                _uiState.value = _uiState.value.copy(gains = gains)
            }
        }
    }

    fun changeEqualizer(gains: FloatArray) {
        deviceManager.changeEqualizer(gains)
    }

    fun connectAndStartStreaming() {
        viewModelScope.launch {
            deviceManager.startBleStreaming().collect {started ->
                _uiState.value = _uiState.value.copy(message = started.toString())
            }
        }
    }

    fun disconnectAndStopStreaming() {
        viewModelScope.launch {
            deviceManager.stopBleStreamingFlow().collect {stopped ->
                _uiState.value = _uiState.value.copy(message = stopped.toString())
            }
        }
    }

    fun startStreaming() {
        viewModelScope.launch {
            deviceManager.startRaceBleStreamingFlow().collect {started ->
                _uiState.value = _uiState.value.copy(message = started.toString())
            }
        }
    }

    fun stopStreaming() {
        viewModelScope.launch {
            deviceManager.stopRaceBleStreamingFlow().collect {stopped ->
                _uiState.value = _uiState.value.copy(message = stopped.toString())
            }
        }
    }
}