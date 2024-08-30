package io.nextsense.android.budz.ui.screens

import android.content.Context
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AirohaBatteryLevel
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AirohaDeviceState
import io.nextsense.android.budz.manager.AudioSample
import io.nextsense.android.budz.manager.AudioSampleType
import io.nextsense.android.budz.manager.AuthRepository
import io.nextsense.android.budz.manager.Protocol
import io.nextsense.android.budz.manager.SoundsManager
import io.nextsense.android.budz.model.UsersRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.last
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.time.Duration.Companion.seconds

data class HomeState(
    val loading: Boolean = false,
    val fallingAsleep: Boolean = false,
    val fallAsleepSample: AudioSample? = null,
    val stayAsleepSample: AudioSample? = null,
    val batteryLevel: AirohaBatteryLevel =
        AirohaBatteryLevel(right = null, left = null, case = null),
    val connected: Boolean = false,
    val restorationBoost: Boolean = true
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val usersRepository: UsersRepository,
    private val authRepository: AuthRepository,
    private val airohaDeviceManager: AirohaDeviceManager
): BudzViewModel(context) {

    private val tag = HomeViewModel::class.java.simpleName
    private val _uiState = MutableStateFlow(HomeState())
    private val _forceStreaming = true
    private var _monitoringJob: Job? = null

    val uiState: StateFlow<HomeState> = _uiState.asStateFlow()

    fun startMonitoring() {
        viewModelScope.launch {
            budzState.collect { budzState ->
                if (budzState.budzServiceBound) {
                    startMonitoringAirohaDevice()
                } else {
                    stopMonitoring()
                }
            }
        }
    }

    private fun startMonitoringAirohaDevice() {
        airohaDeviceManager.initialize()
        _monitoringJob = viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect { deviceState ->
                RotatingFileLogger.get().logd("HomeViewModel", "deviceState: $deviceState")
                when (deviceState) {
                    AirohaDeviceState.CONNECTING_CLASSIC -> {}
                    AirohaDeviceState.READY -> {
                        _uiState.value = _uiState.value.copy(connected = true)
                        getBatteryLevels()
                        if (_forceStreaming) {
                            airohaDeviceManager.setForceStream(true)
                            sessionManager.startSession(
                                protocol = Protocol.WAKE, uploadToCloud = false)
                        }
                    }
                    AirohaDeviceState.CONNECTED_AIROHA -> {}
                    AirohaDeviceState.DISCONNECTED -> {
                        sessionManager.stopSession()
                        _uiState.value = _uiState.value.copy(connected = false,
                            batteryLevel = AirohaBatteryLevel(null, null, null))
                    }
                    else -> {}
                }
            }
        }
    }

    fun stopMonitoring() {
        _monitoringJob?.cancel()
    }

    fun stopConnection() {
        RotatingFileLogger.get().logi("HomeViewModel", "stopConnection")
        airohaDeviceManager.stopConnectingDevice()
    }

    private fun exitApp() {
        RotatingFileLogger.get().logi("HomeViewModel", "exitApp")
        viewModelScope.launch {
            airohaDeviceManager.destroy()
        }
    }

    fun connectDeviceIfNeeded() {
        if (uiState.value.connected) {
            getBatteryLevels()
            if (_forceStreaming) {
                airohaDeviceManager.setForceStream(true)
                viewModelScope.launch {
                    airohaDeviceManager.startBleStreaming()
                }
            }
            return
        }
        connectBoundDevice()
    }

    private fun connectBoundDevice() {
        _uiState.value = _uiState.value.copy(loading = true)
        viewModelScope.launch {
            // Need a bit of delay after initializing the Airoha SDK before connecting.
            delay(1000L)
            // Try to connect when the app is opened in case it is already connected with the
            // device. Timeout after 15 seconds, it will get picked up by the system broadcast when
            // connected later on if not found.
            airohaDeviceManager.connectDevice(timeout = 15.seconds)
        }
    }

    private fun getBatteryLevels() {
        viewModelScope.launch {
            val batteryLevel = airohaDeviceManager.batteryLevelsFlow().take(1).last()
            _uiState.update { currentState ->
                currentState.copy(
                    batteryLevel = batteryLevel
                )
            }
        }
    }

    fun signOut() {
        viewModelScope.launch {
            authRepository.signOut()
        }
        exitApp()
    }

    fun loadUserSounds() {
        _uiState.update { currentState ->
            currentState.copy(
                loading = true
            )
        }
        if (authRepository.currentUserId == null) {
            _uiState.update { currentState ->
                currentState.copy(
                    loading = false
                )
            }
            return
        }
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).let { userState ->
                if (userState is State.Success && userState.data != null) {
                    _uiState.update { currentState ->
                        currentState.copy(
                            fallAsleepSample = SoundsManager.idToSample(
                                userState.data.fallAsleepSound,
                                SoundsManager.defaultAudioSamples[AudioSampleType.FALL_ASLEEP]!!),
                            stayAsleepSample = SoundsManager.idToSample(
                                userState.data.stayAsleepSound,
                                SoundsManager.defaultAudioSamples[AudioSampleType.STAY_ASLEEP]!!)
                        )
                    }
                }
                _uiState.update { currentState ->
                    currentState.copy(
                        loading = false
                    )
                }
            }
        }
    }

    fun setRestorationBoost(value: Boolean) {
        // TODO(eric): Implement restoration boost
        _uiState.update { currentState ->
            currentState.copy(
                restorationBoost = value
            )
        }
    }

    fun startSleeping(context: Context) {
        _uiState.update { currentState ->
            currentState.copy(
                fallingAsleep = true
            )
        }
        SoundsManager.loopAudioSample(
            context = context, resId = uiState.value.fallAsleepSample!!.resId)
    }

    fun pauseSleeping() {
        SoundsManager.pauseAudioSample()
        _uiState.update { currentState ->
            currentState.copy(
                fallingAsleep = false
            )
        }
    }

    fun resumeSleeping() {
        SoundsManager.resumeAudioSample()
        _uiState.update { currentState ->
            currentState.copy(
                fallingAsleep = true
            )
        }
    }

    fun stopSleeping() {
        SoundsManager.stopLoopAudioSample()
        _uiState.update { currentState ->
            currentState.copy(
                fallingAsleep = false
            )
        }
    }
}