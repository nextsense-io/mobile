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

data class CheckConnectionState(
    val connected: Boolean = false,
)

@HiltViewModel
class CheckConnectionViewModel @Inject constructor(
    private val airohaDeviceManager: AirohaDeviceManager
): ViewModel() {

    private val _uiState = MutableStateFlow(CheckConnectionState())

    val uiState: StateFlow<CheckConnectionState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect {deviceState ->
                _uiState.value =
                    CheckConnectionState(connected = deviceState == AirohaDeviceState.READY)
            }
        }
    }
}