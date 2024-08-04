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
    val register: String,
    val registerValue: String,
    val gains: FloatArray = floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f)
)

@HiltViewModel
class DeviceSettingsViewModel @Inject constructor(
        private val deviceManager: AirohaDeviceManager
): ViewModel() {

    private val _uiState = MutableStateFlow(DeviceSettingsState(
        message = "", register = "", registerValue = ""
    ))

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
            _uiState.value = _uiState.value.copy(message = "Starting streaming...")
            val started = deviceManager.startBleStreaming()
            _uiState.value = _uiState.value.copy(message = "Started streaming: $started")
        }
    }

    fun disconnectAndStopStreaming() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(message = "Stopping streaming...")
            val stopped = deviceManager.stopBleStreaming()
            _uiState.value = _uiState.value.copy(message = "Stopped streaming: $stopped")
        }
    }

    fun startSoundLoop() {
        viewModelScope.launch {
            deviceManager.startSoundLoop()
        }
    }

    fun stopSoundLoop() {
        viewModelScope.launch {
            deviceManager.stopSoundLoop()
        }
    }

    fun resetBuds() {
        viewModelScope.launch {
            deviceManager.reset()
        }
    }

    fun powerOffBuds() {
        viewModelScope.launch {
            deviceManager.powerOff()
        }
    }

    fun setRegisterField(register: String) {
        _uiState.value = _uiState.value.copy(register = register)
    }

    fun setRegisterValueField(value: String) {
        _uiState.value = _uiState.value.copy(registerValue = value)
    }

    fun setRegister(register: String, value: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(message = "Setting register...")
            val registerSet = deviceManager.setAfeRegisterValue(register, value)
            _uiState.value = _uiState.value.copy(message = "Register set: $registerSet")
        }
    }

    fun getRegister(register: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(message = "Getting register...")
            val registerValue = deviceManager.getAfeRegisterValue(register)
            if (registerValue != null) {
                _uiState.value = _uiState.value.copy(message = "Got register",
                    registerValue = registerValue)
            } else {
                _uiState.value = _uiState.value.copy(message = "Failed to get register",
                    registerValue = "")
            }
        }
    }
}