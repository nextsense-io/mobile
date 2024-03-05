package io.nextsense.android.main.presentation

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.health.services.client.data.DataTypeAvailability
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.data.MeasureMessage
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HeartRateViewModel @Inject constructor(
    private val healthServicesRepository: HealthServicesRepository,
) : ViewModel() {
    val enabled: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val hr: MutableState<Double> = mutableDoubleStateOf(0.0)
    val availability: MutableState<DataTypeAvailability> =
        mutableStateOf(DataTypeAvailability.UNKNOWN)
    val uiState: MutableState<UiState> = mutableStateOf(UiState.Startup)

    init {
        viewModelScope.launch {
            val supported = healthServicesRepository.hasHeartRateCapability()
            uiState.value = if (supported) {
                UiState.Supported
            } else {
                UiState.NotSupported
            }
            availability.value = healthServicesRepository.availability.value
        }
    }

    fun onMeasureMessage(measureMessage: MeasureMessage) {
        when (measureMessage) {
            is MeasureMessage.MeasureData -> {
                hr.value = measureMessage.data.last().value
            }

            is MeasureMessage.MeasureAvailability -> {
                availability.value = measureMessage.availability
            }
        }
    }

    fun toggleEnabled() {
        enabled.value = !enabled.value
        if (!enabled.value) {
            availability.value = DataTypeAvailability.UNKNOWN
        }
    }
}

class MeasureDataViewModelFactory(
    private val healthServicesRepository: HealthServicesRepository,
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(HeartRateViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST") return HeartRateViewModel(
                healthServicesRepository = healthServicesRepository,
            ) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

sealed class UiState {
    object Startup : UiState()
    object NotSupported : UiState()
    object Supported : UiState()
}
