package io.nextsense.android.main.presentation

import android.os.SystemClock
import android.util.Log
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.health.services.client.data.DataTypeAvailability
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import io.nextsense.android.main.TAG
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.data.MeasureMessage
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.takeWhile
import kotlinx.coroutines.launch

class HeartRateViewModel(
    private val healthServicesRepository: HealthServicesRepository,
    private val localDatabaseManager: LocalDatabaseManager
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
        }
        viewModelScope.launch {
            enabled.collect {
                if (it) {
                    healthServicesRepository.heartRateMeasureFlow().takeWhile { enabled.value }
                        .collect { measureMessage ->
                            when (measureMessage) {
                                is MeasureMessage.MeasureData -> {
                                    hr.value = measureMessage.data.last().value
                                    saveHeartRateData(hr.value)
                                }

                                is MeasureMessage.MeasureAvailability -> {
                                    availability.value = measureMessage.availability
                                }
                            }
                        }
                }
            }
        }
    }

    fun toggleEnabled() {
        enabled.value = !enabled.value
        if (!enabled.value) {
            availability.value = DataTypeAvailability.UNKNOWN
        }
    }

    private fun saveHeartRateData(heartRate: Double) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val heartRateEntity = HeartRateEntity(
                    heartRate = heartRate, createAt = SystemClock.currentThreadTimeMillis()
                )
                localDatabaseManager.heartRateDao?.insertAll(heartRateEntity)
            } catch (e: Exception) {
                Log.i(TAG, "${e.message}")
            }
        }
    }

    fun saveAccelerometerData(timestamp: Long, x: Double, y: Double, z: Double) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val accelerometerEntity = AccelerometerEntity(
                    x = x, y = y, z = z, createAt = timestamp
                )
                localDatabaseManager.accelerometerDao?.insertAll(accelerometerEntity)
            } catch (e: Exception) {
                Log.i(TAG, "${e.message}")
            }
        }
    }
}

class MeasureDataViewModelFactory(
    private val healthServicesRepository: HealthServicesRepository,
    private val localDatabaseManager: LocalDatabaseManager
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(HeartRateViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST") return HeartRateViewModel(
                healthServicesRepository = healthServicesRepository,
                localDatabaseManager = localDatabaseManager,
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
