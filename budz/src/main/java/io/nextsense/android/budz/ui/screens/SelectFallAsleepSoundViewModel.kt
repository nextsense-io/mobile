package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.util.Log
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

data class SelectFallAsleepSoundState(
    val audioSample: AudioSample? = null,
    val playing: Boolean = false,
    val loading: Boolean = false
)

@HiltViewModel
class SelectFallAsleepSoundViewModel @Inject constructor(
    private val usersRepository: UsersRepository,
    private val authRepository: AuthRepository
): ViewModel() {

    private val tag = SelectFallAsleepSoundViewModel::class.java.simpleName
    private val _uiState = MutableStateFlow(SelectFallAsleepSoundState())

    val uiState: StateFlow<SelectFallAsleepSoundState> = _uiState.asStateFlow()

    init {
        _uiState.update { currentState ->
            currentState.copy(
                loading = true
            )
        }
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).last().let { userState ->
                if (userState is State.Success && userState.data != null) {
                    _uiState.update { currentState ->
                        currentState.copy(
                            audioSample = SoundsManager.idToSample(
                                userState.data.fallAsleepSound,
                                SoundsManager.defaultFallAsleepAudioSample)
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

    fun playAudioSample(context: Context, audioSample: AudioSample) {
        SoundsManager.playAudioSample(context, audioSample.resId,
            onComplete = {_uiState.update { currentState ->
                currentState.copy(
                    playing = false
                )
            }})
        _uiState.update { currentState ->
            currentState.copy(
                playing = true
            )
        }
    }

    fun stopPlayingSample() {
        SoundsManager.stopAudioSample()
        _uiState.update { currentState ->
            currentState.copy(
                playing = false
            )
        }
    }

    fun changeFallAsleepSound(audioSample: AudioSample) {
        _uiState.update { currentState ->
            currentState.copy(
                audioSample = audioSample
            )
        }
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).last().let { userState ->
                if (userState is State.Success) {
                    if (userState.data != null) {
                        usersRepository.updateUser(
                            userState.data.copy(fallAsleepSound = audioSample.id),
                            authRepository.currentUserId!!
                        ).last().let { updateState ->
                            if (updateState is State.Success) {
                                _uiState.update { currentState ->
                                    currentState.copy(
                                        audioSample = audioSample
                                    )
                                }
                            } else {
                                Log.d(tag, "Failed to update user fall asleep sound")
                            }
                        }
                    }
                }
            }
        }
    }
}