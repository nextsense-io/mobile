package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.os.CountDownTimer
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AudioSample
import io.nextsense.android.budz.manager.AuthRepository
import io.nextsense.android.budz.manager.SoundsManager
import io.nextsense.android.budz.model.UsersRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.last
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

    private val _uiState = MutableStateFlow(TimedSleepState())
    private var _sleepTimer: CountDownTimer? = null

    val uiState: StateFlow<TimedSleepState> = _uiState.asStateFlow()

    init {
        loadUserSounds()
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
                fallingAsleep = false
            )
        }
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
            usersRepository.getUser(authRepository.currentUserId!!).last().let { userState ->
                if (userState is State.Success && userState.data != null) {
                    _uiState.update { currentState ->
                        currentState.copy(
                            fallAsleepSample = SoundsManager.idToSample(
                                userState.data.fallAsleepSound,
                                SoundsManager.defaultFallAsleepAudioSample),
                            stayAsleepSample = SoundsManager.idToSample(
                                userState.data.stayAsleepSound,
                                SoundsManager.defaultStayAsleepAudioSample)
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
}