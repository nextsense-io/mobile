package io.nextsense.android.budz.ui.screens

import android.content.Context
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AirohaDeviceState
import io.nextsense.android.budz.manager.Protocol
import io.nextsense.android.budz.manager.SessionState
import io.nextsense.android.budz.model.ActivityType
import io.nextsense.android.budz.model.DataQuality
import io.nextsense.android.budz.model.ToneBud
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DataCollectionState(
    val connected: Boolean = false,
    val recordingState: SessionState = SessionState.STOPPED,
    val activityType: ActivityType = ActivityType.UNKNOWN,
    val dataQuality: DataQuality = DataQuality.UNKNOWN,
    val toneBud: ToneBud = ToneBud.UNKNOWN,
)

@HiltViewModel
class DataCollectionViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val deviceManager: AirohaDeviceManager
): BudzViewModel(context) {

    private var _monitoringJob: Job? = null
    private val _uiState = MutableStateFlow(DataCollectionState(
        recordingState = SessionState.STOPPED
    ))

    val uiState: StateFlow<DataCollectionState> = _uiState.asStateFlow()

    fun setActivityType(activityType: ActivityType) {
        _uiState.value = _uiState.value.copy(activityType = activityType)
    }

    fun setDataQuality(dataQuality: DataQuality) {
        _uiState.value = _uiState.value.copy(dataQuality = dataQuality)
    }

    fun setToneBud(toneBud: ToneBud) {
        _uiState.value = _uiState.value.copy(toneBud = toneBud)
    }

    fun startStopRecording() {
        viewModelScope.launch {
            if (_uiState.value.recordingState == SessionState.STARTED) {
                stopSession()
            } else {
                startSession()
            }
        }
    }

    private suspend fun startSession() {
        _uiState.value = _uiState.value.copy(recordingState = SessionState.STARTING)
        if (sessionManager.isSessionRunning()) {
            sessionManager.stopSession()
        }
        deviceManager.setForceStream(true)
        sessionManager.startSession(protocol = Protocol.WAKE, uploadToCloud = true,
            activityType = _uiState.value.activityType, toneBud = _uiState.value.toneBud)
        _uiState.value = _uiState.value.copy(recordingState = SessionState.STARTED)
    }

    private suspend fun stopSession() {
        _uiState.value = _uiState.value.copy(recordingState = SessionState.STOPPING)
        sessionManager.stopSession(dataQuality = _uiState.value.dataQuality)
        _uiState.value = _uiState.value.copy(recordingState = SessionState.STOPPED,
            activityType = ActivityType.UNKNOWN, dataQuality = DataQuality.UNKNOWN,
            toneBud = ToneBud.UNKNOWN)
    }

    fun startMonitoring() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(connected =
                deviceManager.airohaDeviceState.value == AirohaDeviceState.READY)
            budzState.collect { budzState ->
                if (budzState.budzServiceBound) {
                    if (sessionManager.currentSession != null) {
                        _uiState.value = _uiState.value.copy(
                            recordingState = sessionManager.sessionState,
                            activityType = sessionManager.currentSession?.activityType
                                ?: ActivityType.UNKNOWN,
                            dataQuality = sessionManager.currentSession?.dataQuality
                                ?: DataQuality.UNKNOWN,
                            toneBud = sessionManager.currentSession?.toneBud ?: ToneBud.UNKNOWN
                        )
                    }
                    startMonitoringAirohaDevice()
                } else {
                    stopMonitoring()
                }
            }
        }
    }

    private fun startMonitoringAirohaDevice() {
        deviceManager.initialize()
        _monitoringJob = viewModelScope.launch {
            deviceManager.airohaDeviceState.collect { deviceState ->
                RotatingFileLogger.get().logd("HomeViewModel", "deviceState: $deviceState")
                when (deviceState) {
                    AirohaDeviceState.READY -> {
                        _uiState.value = _uiState.value.copy(connected = true)
                    }
                    AirohaDeviceState.DISCONNECTED -> {
                        stopSession()
                        _uiState.value = _uiState.value.copy(connected = false)
                    }
                    else -> {}
                }
            }
        }
    }

    fun stopMonitoring() {
        _monitoringJob?.cancel()
    }
}