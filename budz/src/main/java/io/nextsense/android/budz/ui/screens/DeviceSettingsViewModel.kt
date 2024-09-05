package io.nextsense.android.budz.ui.screens

import android.content.Context
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.Protocol
import io.nextsense.android.budz.manager.StreamingState
import io.nextsense.android.budz.model.DataQuality
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
    val sleepMode: Boolean = false,
    val serviceBound: Boolean = false,
    val streaming: StreamingState = StreamingState.UNKNOWN
)

@HiltViewModel
class DeviceSettingsViewModel @Inject constructor(
    @ApplicationContext context: Context,
    private val deviceManager: AirohaDeviceManager
): BudzViewModel(context) {

    private val _uiState = MutableStateFlow(
        DeviceSettingsState(
            message = "", register = "", registerValue = ""
        )
    )

    val uiState: StateFlow<DeviceSettingsState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            budzState.collect { budzState ->
                if (budzState.budzServiceBound) {
                    _uiState.value = _uiState.value.copy(serviceBound = true)
                    deviceManager.streamingState.collect { streamingState ->
                        _uiState.value = _uiState.value.copy(streaming = streamingState)
                    }
                } else {
                    _uiState.value = _uiState.value.copy(serviceBound = false)
                }
            }
        }
    }

    fun startStreaming() {
        viewModelScope.launch {
            sessionManager.startSession(Protocol.WAKE, uploadToCloud = false)
        }
    }

    fun stopStreaming() {
        viewModelScope.launch {
            sessionManager.stopSession(dataQuality = DataQuality.UNKNOWN)
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
}



