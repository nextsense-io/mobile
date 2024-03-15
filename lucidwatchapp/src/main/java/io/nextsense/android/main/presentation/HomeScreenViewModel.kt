package io.nextsense.android.main.presentation

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.main.data.DataTypeAvailability
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.utils.Logger
import io.nextsense.android.main.utils.PreferenceType
import io.nextsense.android.main.utils.SharedPreferencesData
import io.nextsense.android.main.utils.SharedPreferencesHelper
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeScreenViewModel @Inject constructor(
    private val healthServicesRepository: HealthServicesRepository,
    private val sharedPreferencesHelper: SharedPreferencesHelper,
    private val logger: Logger
) : ViewModel() {
    val enabled: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val availability: MutableState<DataTypeAvailability> =
        mutableStateOf(DataTypeAvailability.UNKNOWN)
    val uiState: MutableState<UiState> = mutableStateOf(UiState.Startup)
    val onExitEvent: MutableState<UiState> = mutableStateOf(UiState.Startup)
    val isUserLogin = sharedPreferencesHelper.getValueForKey(
        SharedPreferencesData.isUserLogin, PreferenceType.BoolType, false
    ).stateIn(
        viewModelScope, SharingStarted.Eagerly, false
    )
    val isRealitySettingCreated = sharedPreferencesHelper.getValueForKey(
        SharedPreferencesData.LucidSettings, PreferenceType.StringType, ""
    ).stateIn(
        viewModelScope, SharingStarted.Eagerly, ""
    )

    init {
        viewModelScope.launch {
            val supported = healthServicesRepository.hasHeartRateCapability()
            uiState.value = if (supported) {
                UiState.Supported
            } else {
                UiState.NotSupported
            }
        }
    }

    fun toggleEnabled() {
        enabled.value = !enabled.value
        if (!enabled.value) {
            availability.value = DataTypeAvailability.UNKNOWN
        }
    }

    fun onExit() {
        onExitEvent.value = UiState.Exit
    }
}

sealed class UiState {
    object Startup : UiState()
    object NotSupported : UiState()
    object Supported : UiState()
    object Exit : UiState()
}