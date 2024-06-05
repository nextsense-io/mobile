package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.os.CountDownTimer
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AudioSample
import io.nextsense.android.budz.manager.AudioSampleType
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

data class FocusState(
    val loading: Boolean = false,
    val focusing: Boolean = false,
    val focusSample: AudioSample? = null,
    val connected: Boolean = false,
    val focusTime: Duration = 1.minutes,
    val focusTimeLeft: Duration = 1.minutes
)

@HiltViewModel
class FocusViewModel @Inject constructor(
    private val usersRepository: UsersRepository,
    private val authRepository: AuthRepository
): ViewModel() {

    private val tag = FocusViewModel::class.java.simpleName
    private val _uiState = MutableStateFlow(FocusState())
    private var _focusTimer: CountDownTimer? = null

    val uiState: StateFlow<FocusState> = _uiState.asStateFlow()

    fun startFocusing(context: Context) {
        _uiState.update { currentState ->
            currentState.copy(
                focusing = true
            )
        }
        SoundsManager.loopAudioSample(
            context = context, resId = uiState.value.focusSample!!.resId)
        _focusTimer = object: CountDownTimer(_uiState.value.focusTime.inWholeMilliseconds, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                _uiState.update { currentState ->
                    currentState.copy(
                        focusTimeLeft = (millisUntilFinished / 1000).seconds
                    )
                }
            }

            override fun onFinish() {
                stopFocusing()
            }
        }
        _focusTimer?.start()
    }

    fun stopFocusing() {
        _focusTimer?.cancel()
        _focusTimer = null
        SoundsManager.stopLoopAudioSample()
        _uiState.update { currentState ->
            currentState.copy(
                focusing = false,
                focusTimeLeft = currentState.focusTime
            )
        }
    }

    fun changeFocusTime(newFocusTime: Duration) {
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).last().let { userState ->
                if (userState is State.Success) {
                    if (userState.data != null) {
                        val userStateData = userState.data.copy(
                            focusDurationMinutes = newFocusTime.inWholeMinutes.toInt())
                        usersRepository.updateUser(userStateData, authRepository.currentUserId!!)
                            .last().let { updateState ->
                                if (updateState is State.Success) {
                                    _uiState.update { currentState ->
                                        currentState.copy(
                                            focusTime = newFocusTime,
                                            focusTimeLeft = newFocusTime
                                        )
                                    }
                                } else {
                                    Log.d(tag, "Failed to update focus duration")
                                }
                            }
                    }
                }
            }
        }
    }

    fun loadUserData() {
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
                        val focusTime = userState.data.focusDurationMinutes?.minutes ?: 10.minutes
                        currentState.copy(
                            focusTime = focusTime,
                            focusTimeLeft = focusTime,
                            focusSample = SoundsManager.idToSample(
                                userState.data.focusSound,
                                SoundsManager.defaultAudioSamples[AudioSampleType.FOCUS]!!),
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