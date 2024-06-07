package io.nextsense.android.budz.ui.screens

import android.util.Log
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
import kotlin.time.Duration.Companion.seconds

data class IntroState(
    val connecting: Boolean = false,
    val connected: Boolean = false,
)

@HiltViewModel
class IntroViewModel @Inject constructor(
    private val airohaDeviceManager: AirohaDeviceManager
): ViewModel() {

    private val _uiState = MutableStateFlow(IntroState())

    val uiState: StateFlow<IntroState> = _uiState.asStateFlow()

    fun connectBoundDevice(onConnected: () -> Unit) {
        _uiState.value = _uiState.value.copy(connecting = true)
        viewModelScope.launch {
            // Need a bit of delay (about 1 second) after initializing the Airoha SDK before
            // connecting, but it is fine as the user needs to move through 4 screens.
            airohaDeviceManager.connectDevice(timeout = 30.seconds)
        }
        viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect { deviceState ->
                Log.d("HomeViewModel", "deviceState: $deviceState")
                when (deviceState) {
                    AirohaDeviceState.CONNECTING_CLASSIC -> {
                        _uiState.value = _uiState.value.copy(connecting = true)
                    }
                    AirohaDeviceState.READY -> {
                        _uiState.value = _uiState.value.copy(connected = true)
                        onConnected()
                    }
                    AirohaDeviceState.CONNECTED_AIROHA -> {
                        _uiState.value = _uiState.value.copy(connected = true)
                    }
                    else -> {
                        // _uiState.value = IntroState()
                    }
                }
            }
        }
    }

    fun stopConnecting() {
        viewModelScope.launch {
            airohaDeviceManager.stopConnectingDevice()
        }
    }
}