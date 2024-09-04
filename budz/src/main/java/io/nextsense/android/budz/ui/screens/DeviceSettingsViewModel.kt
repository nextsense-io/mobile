package io.nextsense.android.budz.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.airoha.device.DisableVoicePromptRaceCommand
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
    val soundLoopVolume: Int? = null,
    val gains: FloatArray = floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f)
)

@HiltViewModel
class DeviceSettingsViewModel @Inject constructor(
        private val deviceManager: AirohaDeviceManager
): ViewModel() {

    private val _uiState = MutableStateFlow(
        DeviceSettingsState(
            message = "", register = "", registerValue = ""
        )
    )

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
            deviceManager.startBleStreaming()
            _uiState.value = _uiState.value.copy(message = "Started streaming")
        }
    }

    fun disconnectAndStopStreaming() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(message = "Stopping streaming...")
            deviceManager.stopBleStreaming(overrideForceStreaming = true)
            _uiState.value = _uiState.value.copy(message = "Stopped streaming")
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

    fun setSoundLoopVolume(volume: Int?) {
        if (volume == null) {
            return
        }
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(message = "Setting sound loop volume...")
            val set = deviceManager.setSoundLoopVolume(volume)
            _uiState.value = _uiState.value.copy(message = "Sound loop volume set: $set")
        }
    }

    fun getSoundLoopVolume() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(message = "Getting sound loop volume...")
            val volume = deviceManager.getSoundLoopVolume()
            if (volume != null) {
                _uiState.value = _uiState.value.copy(
                    message = "Got sound loop volume",
                    soundLoopVolume = volume
                )
            } else {
                _uiState.value = _uiState.value.copy(
                    message = "Failed to get register",
                    soundLoopVolume = null
                )
            }
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

    fun setSoundLoopVolumeField(volume: String) {
        val volumeInt = volume.toIntOrNull() ?: 0
        _uiState.value = _uiState.value.copy(soundLoopVolume = volumeInt)
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
                _uiState.value = _uiState.value.copy(
                    message = "Got register",
                    registerValue = registerValue
                )
            } else {
                _uiState.value = _uiState.value.copy(
                    message = "Failed to get register",
                    registerValue = ""
                )
            }
        }
    }

    fun disableVoicePrompt(disable: Boolean) {
        viewModelScope.launch {
            deviceManager.disableVoicePrompt(disable)
            _uiState.value =
                _uiState.value.copy(message = "Voice prompt ${if (disable) "disabled" else "enabled"}")
        }
    }
}



