package io.nextsense.android.main.presentation

import android.app.Application
import android.util.Log
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.health.services.client.data.DataTypeAvailability
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import io.nextsense.android.main.TAG
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.data.MeasureMessage
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import io.nextsense.android.main.utils.NotificationManager
import io.nextsense.android.main.utils.SleepStagePredictionHelper
import io.nextsense.android.main.utils.SleepStagePredictionOutput
import io.nextsense.android.main.utils.minutesToMilliseconds
import io.nextsense.android.main.utils.toSeconds
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.takeWhile
import kotlinx.coroutines.launch
import java.time.Duration

class HeartRateViewModel(
    private val application: Application,
    private val healthServicesRepository: HealthServicesRepository,
    private val localDatabaseManager: LocalDatabaseManager,
    private val sleepStagePredictionHelper: SleepStagePredictionHelper = SleepStagePredictionHelper.instance
) : AndroidViewModel(application) {
    val enabled: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val hr: MutableState<Double> = mutableDoubleStateOf(0.0)
    val availability: MutableState<DataTypeAvailability> =
        mutableStateOf(DataTypeAvailability.UNKNOWN)
    val uiState: MutableState<UiState> = mutableStateOf(UiState.Startup)
    private val dataCheckingPeriod: Long = MILLISECONDS_PER_SECOND * 30.toLong()
    private val initialWaitingTime = minutesToMilliseconds(15)
    private var initialWaitingTimeCompleted = false

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
        viewModelScope.launch(Dispatchers.Default) {
            enabled.collectLatest {
                while (it) {
                    if (initialWaitingTimeCompleted) {
                        val context = application.applicationContext
                        val heartRateData = localDatabaseManager.fetchHeartRateDate(
                            duration = Duration.ofMinutes(30)
                        )
                        val accelerometerData = localDatabaseManager.fetchAccelerometerData(
                            duration = Duration.ofMinutes(5)
                        )
                        val result = viewModelScope.async {
                            sleepStagePredictionHelper.prediction(
                                context = context,
                                inputData = heartRateData,
                                accelerometerData = accelerometerData,
                                workoutStartTime = System.currentTimeMillis().toSeconds()
                            )
                        }.await()
                        when (result) {
                            SleepStagePredictionOutput.REM -> {
                                NotificationManager(context).showNotification(
                                    title = "REM",
                                    message = "This is lucid night notification."
                                )
                            }

                            else -> {
                                Log.i(TAG, "Model Result=>${result}")
                            }
                        }
                    }
                    delay(if (initialWaitingTimeCompleted) dataCheckingPeriod else initialWaitingTime.toLong())
                    initialWaitingTimeCompleted = true
                }
            }
        }
    }

    fun toggleEnabled() {
        enabled.value = !enabled.value
        if (!enabled.value) {
            availability.value = DataTypeAvailability.UNKNOWN
            initialWaitingTimeCompleted = false
        }
    }

    private fun saveHeartRateData(heartRate: Double) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val heartRateEntity = HeartRateEntity(
                    heartRate = heartRate, createAt = System.currentTimeMillis().toSeconds()
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
                    x = x, y = y, z = z, createAt = timestamp.toSeconds()
                )
                localDatabaseManager.accelerometerDao?.insertAll(accelerometerEntity)
            } catch (e: Exception) {
                Log.i(TAG, "${e.message}")
            }
        }
    }

}

class MeasureDataViewModelFactory(
    private val application: Application,
    private val healthServicesRepository: HealthServicesRepository,
    private val localDatabaseManager: LocalDatabaseManager
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(HeartRateViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST") return HeartRateViewModel(
                application = application,
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
