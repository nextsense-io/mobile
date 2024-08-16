package io.nextsense.android.budz.ui.screens

import android.content.Context
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

data class SelectSoundState(
    val audioSample: AudioSample? = null,
    val playing: Boolean = false,
    val loading: Boolean = false
)

@HiltViewModel
class SelectSoundViewModel @Inject constructor(
    private val usersRepository: UsersRepository,
    private val authRepository: AuthRepository
): ViewModel() {

    private val tag = SelectSoundViewModel::class.java.simpleName
    private val _uiState = MutableStateFlow(SelectSoundState())

    val uiState: StateFlow<SelectSoundState> = _uiState.asStateFlow()

    fun loadAudioSample(audioSampleType: AudioSampleType) {
        _uiState.update { currentState ->
            currentState.copy(
                loading = true
            )
        }
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).let { userState ->
                if (userState is State.Success && userState.data != null) {
                    _uiState.update { currentState ->
                        var audioSampleName: String? = null
                        when (audioSampleType) {
                            AudioSampleType.FALL_ASLEEP -> {
                                audioSampleName = userState.data.fallAsleepSound
                            }
                            AudioSampleType.FALL_ASLEEP_TIMED_SLEEP -> {
                                audioSampleName = userState.data.fallAsleepTimedSound
                                if (audioSampleName == null) {
                                    audioSampleName = userState.data.fallAsleepSound
                                }
                            }
                            AudioSampleType.STAY_ASLEEP -> {
                                audioSampleName = userState.data.stayAsleepSound
                            }
                            AudioSampleType.STAY_ASLEEP_TIMED_SLEEP -> {
                                audioSampleName = userState.data.stayAsleepTimedSound
                                if (audioSampleName == null) {
                                    audioSampleName = userState.data.stayAsleepSound
                                }
                            }
                            AudioSampleType.FOCUS -> {
                                audioSampleName = userState.data.focusSound
                            }
                        }
                        val audioSample = SoundsManager.idToSample(
                            audioSampleName,
                            SoundsManager.defaultAudioSamples[audioSampleType]!!
                        )
                        currentState.copy(audioSample = audioSample)
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

    fun changeSound(audioSampleType: AudioSampleType, audioSample: AudioSample) {
        _uiState.update { currentState ->
            currentState.copy(
                audioSample = audioSample
            )
        }
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).let { userState ->
                if (userState is State.Success) {
                    if (userState.data != null) {
                        var userStateData = userState.data
                        when (audioSampleType) {
                            AudioSampleType.FALL_ASLEEP -> {
                                userStateData = userStateData.copy(fallAsleepSound = audioSample.id)
                            }
                            AudioSampleType.FALL_ASLEEP_TIMED_SLEEP -> {
                                userStateData = userStateData.copy(
                                    fallAsleepTimedSound = audioSample.id)
                            }
                            AudioSampleType.STAY_ASLEEP -> {
                                userStateData = userStateData.copy(stayAsleepSound = audioSample.id)
                            }
                            AudioSampleType.STAY_ASLEEP_TIMED_SLEEP -> {
                                userStateData = userStateData.copy(
                                    stayAsleepTimedSound = audioSample.id)
                            }
                            AudioSampleType.FOCUS -> {
                                userStateData = userStateData.copy(focusSound = audioSample.id)
                            }
                        }
                        usersRepository.updateUser(userStateData, authRepository.currentUserId!!)
                            .let { updateState ->
                            if (updateState is State.Success) {
                                _uiState.update { currentState ->
                                    currentState.copy(
                                        audioSample = audioSample
                                    )
                                }
                            } else {
                                RotatingFileLogger.get().logd(tag, "Failed to update user " +
                                        "${audioSampleType.name} sound")
                            }
                        }
                    }
                }
            }
        }
    }
}