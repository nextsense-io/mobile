package io.nextsense.android.budz.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AirohaDeviceState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DeviceConnectionState(
    val connecting: Boolean = false,
    val connected: Boolean = false,
    val connectedWrongRole: Boolean = false
)

@HiltViewModel
class DeviceConnectionViewModel @Inject constructor(
        private val deviceManager: AirohaDeviceManager
): ViewModel() {

    private val _uiState = MutableStateFlow(DeviceConnectionState())

    val uiState: StateFlow<DeviceConnectionState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            deviceManager.deviceState.collect { deviceState ->
                when (deviceState) {
                    AirohaDeviceState.READY -> {
                        _uiState.value = _uiState.value.copy(connected = true, connecting = false)
                    }
                    AirohaDeviceState.CONNECTED_AIROHA -> {
                        _uiState.value = _uiState.value.copy(connected = true, connecting = false)
                    }
                    AirohaDeviceState.CONNECTED_AIROHA_WRONG_ROLE -> {
                        _uiState.value = _uiState.value.copy(connectedWrongRole = true)
                    }
                    else -> {
                        _uiState.value = DeviceConnectionState()
                    }
                }
            }
        }
    }

    fun connectBoundDevice() {
        _uiState.value = _uiState.value.copy(connecting = true)
        viewModelScope.launch {
            deviceManager.connectDevice()
        }
    }
}