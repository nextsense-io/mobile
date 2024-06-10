package io.nextsense.android.budz.ui.screens

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AirohaDeviceState
import io.nextsense.android.budz.manager.AuthRepository
import io.nextsense.android.budz.model.UsersRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.time.Duration.Companion.seconds

data class IntroState(
    val connecting: Boolean = false,
    val connected: Boolean = false,
)

@HiltViewModel
class IntroViewModel @Inject constructor(
    private val airohaDeviceManager: AirohaDeviceManager,
    private val authRepository: AuthRepository,
    private val usersRepository: UsersRepository
): ViewModel() {

    private val tag = IntroViewModel::class.java.simpleName
    private val _uiState = MutableStateFlow(IntroState())

    val uiState: StateFlow<IntroState> = _uiState.asStateFlow()

    private suspend fun setOnboardingCompleted() {
        viewModelScope.launch {
            usersRepository.getUser(authRepository.currentUserId!!).let { userState ->
                if (userState is State.Success) {
                    if (userState.data != null) {
                        val userStateData = userState.data.copy(isOnboardingCompleted = true)
                        usersRepository.updateUser(userStateData, authRepository.currentUserId!!)
                            .let { updateState ->
                                if (updateState is State.Success) {
                                    return@launch
                                } else {
                                    Log.d(tag, "Failed to update user is onboarding completed")
                                }
                            }
                    }
                }
            }
        }
    }

    fun connectBoundDevice(onConnected: () -> Unit) {
        _uiState.value = _uiState.value.copy(connecting = true)
        viewModelScope.launch {
            // Need a bit of delay (about 1 second) after initializing the Airoha SDK before
            // connecting, but it is fine as the user needs to move through 4 screens.
            airohaDeviceManager.connectDevice(timeout = 30.seconds)
        }
        viewModelScope.launch {
            airohaDeviceManager.airohaDeviceState.collect { deviceState ->
                Log.d("HomeViewModel", "deviceState: $deviceState")
                when (deviceState) {
                    AirohaDeviceState.CONNECTING_CLASSIC -> {
                        _uiState.value = _uiState.value.copy(connecting = true)
                    }
                    AirohaDeviceState.READY -> {
                        _uiState.value = _uiState.value.copy(connected = true)
                        setOnboardingCompleted().let {
                            onConnected()
                        }
                    }
                    AirohaDeviceState.CONNECTED_AIROHA -> {
                        _uiState.value = _uiState.value.copy(connected = true)
                    }
                    else -> {
                        // _uiState.value = IntroState()
                    }
                }
            }
        }
    }

    fun stopConnecting() {
        viewModelScope.launch {
            airohaDeviceManager.stopConnectingDevice()
        }
    }
}