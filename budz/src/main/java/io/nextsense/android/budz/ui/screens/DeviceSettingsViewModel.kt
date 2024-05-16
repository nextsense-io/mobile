package io.nextsense.android.budz.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.device.DeviceManager
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
        private val deviceManager: DeviceManager): ViewModel() {

    private val _uiState = MutableStateFlow(DeviceSettingsState(""))

    val uiState: StateFlow<DeviceSettingsState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            deviceManager.equalizerState.asStateFlow().collect { gains ->
                _uiState.value = _uiState.value.copy(gains = gains)
            }
        }
    }

    fun changeEqualizer(gains: FloatArray) {
        deviceManager.changeEqualizer(gains)
    }

}