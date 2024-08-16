package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.os.CountDownTimer
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AudioSample
import io.nextsense.android.budz.manager.AudioSampleType
import io.nextsense.android.budz.manager.AuthRepository
import io.nextsense.android.budz.manager.SoundsManager
import io.nextsense.android.budz.model.UsersRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

data class TimedSleepState(
    val loading: Boolean = false,
    val fallingAsleep: Boolean = false,
    val fallAsleepSample: AudioSample? = null,
    val stayAsleepSample: AudioSample? = null,
    val connected: Boolean = false,
    val sleepTime: Duration = 1.minutes,
    val sleepTimeLeft: Duration = 1.minutes
)

@HiltViewModel
class TimedSleepViewModel @Inject constructor(
    private val usersRepository: UsersRepository,
    private val authRepository: AuthRepository
): ViewModel() {

    private val tag = TimedSleepViewModel::class.java.simpleName
    private val _uiState = MutableStateFlow(TimedSleepState())
    private var _sleepTimer: CountDownTimer? = null

    val uiState: StateFlow<TimedSleepState> = _uiState.asStateFlow()

    init {
        loadUserData()
    }

    fun startSleeping(context: Context) {
        _uiState.update { currentState ->
            currentState.copy(
                fallingAsleep = true
            )
        }
        SoundsManager.loopAudioSample(
            context = context, resId = uiState.value.fallAsleepSample!!.resId)
        _sleepTimer = object: CountDownTimer(_uiState.value.sleepTime.inWholeMilliseconds, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                _uiState.update { currentState ->
                    currentState.copy(
                        sleepTimeLeft = (millisUntilFinished / 1000).seconds
                    )
                }
            }

            override fun onFinish() {
                stopSleeping()
            }
        }
        _sleepTimer?.start()
    }

    fun stopSleeping() {
        _sleepTimer?.cancel()
        _sleepTimer = null
        SoundsManager.stopLoopAudioSample()
        _uiState.update { currentState ->
            currentState.copy(
                fallingAsleep = false,
                sleepTimeLeft = currentState.sleepTime
            )
        }
    }

    fun changeSleepTime(newSleepTime: Duration) {
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).let { userState ->
                if (userState is State.Success) {
                    if (userState.data != null) {
                        val userStateData = userState.data.copy(
                            timedSleepDurationMinutes = newSleepTime.inWholeMinutes.toInt())
                        usersRepository.updateUser(userStateData, authRepository.currentUserId!!)
                            .let { updateState ->
                                if (updateState is State.Success) {
                                    _uiState.update { currentState ->
                                        currentState.copy(
                                            sleepTime = newSleepTime,
                                            sleepTimeLeft = newSleepTime
                                        )
                                    }
                                } else {
                                    RotatingFileLogger.get().logd(tag, "Failed to update timed " +
                                            "sleep duration")
                                }
                            }
                    }
                }
            }
        }
    }

    fun loadUserData() {
        RotatingFileLogger.get().logd(tag, "updating state")
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
        RotatingFileLogger.get().logd(tag, "loading user data")
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).let { userState ->
                RotatingFileLogger.get().logd(tag, "user data loaded")
                if (userState is State.Success && userState.data != null) {
                    _uiState.update { currentState ->
                        val fallAsleepSampleName =
                            if (userState.data.fallAsleepTimedSound == null) {
                                userState.data.fallAsleepSound
                            } else {
                                userState.data.fallAsleepTimedSound
                            }
                        val stayAsleepSampleName =
                            if (userState.data.stayAsleepTimedSound == null) {
                                userState.data.stayAsleepSound
                            } else {
                                userState.data.stayAsleepTimedSound
                            }
                        val timedSleepDuration: Duration =
                            if (userState.data.timedSleepDurationMinutes != null) {
                                (userState.data.timedSleepDurationMinutes)!!.minutes
                            } else {
                                30.minutes
                            }
                        currentState.copy(
                            sleepTime = timedSleepDuration,
                            sleepTimeLeft = timedSleepDuration,
                            connected = true,
                            fallAsleepSample = SoundsManager.idToSample(
                                fallAsleepSampleName,
                                SoundsManager.defaultAudioSamples[
                                    AudioSampleType.FALL_ASLEEP_TIMED_SLEEP]!!),
                            stayAsleepSample = SoundsManager.idToSample(
                                stayAsleepSampleName,
                                SoundsManager.defaultAudioSamples[
                                    AudioSampleType.STAY_ASLEEP_TIMED_SLEEP]!!)
                        )
                    }
                    RotatingFileLogger.get().logd(tag, "state updated")
                }
                _uiState.update { currentState ->
                    currentState.copy(
                        loading = false
                    )
                }
            }
        }
    }
}