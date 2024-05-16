package io.nextsense.android.budz.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.device.DeviceManager
import io.nextsense.android.budz.manager.device.DeviceState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DeviceConnectionState(
    val connecting: Boolean = false,
    val connected: Boolean = false,
    val connectedWrongRole: Boolean = false
)

@HiltViewModel
class DeviceConnectionViewModel @Inject constructor(
        private val deviceManager: DeviceManager): ViewModel() {

    private val _uiState = MutableStateFlow(DeviceConnectionState())

    val uiState: StateFlow<DeviceConnectionState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            deviceManager.deviceState.asStateFlow().collect { deviceState ->
                when (deviceState) {
                    DeviceState.CONNECTED_AIROHA -> {
                        _uiState.value = _uiState.value.copy(connected = true, connecting = false)
                    }
                    DeviceState.CONNECTED_AIROHA_WRONG_ROLE -> {
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