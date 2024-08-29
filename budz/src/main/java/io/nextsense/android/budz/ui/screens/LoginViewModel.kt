package io.nextsense.android.budz.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AuthRepository
import io.nextsense.android.budz.model.UsersRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class LoginState(
    val loading: Boolean = false
)

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val usersRepository: UsersRepository,
    private val authRepository: AuthRepository
): ViewModel() {

    private val _uiState = MutableStateFlow(LoginState())

    val uiState: StateFlow<LoginState> = _uiState.asStateFlow()

    fun navigateToNext(goToIntro: () -> Unit, goToHome: () -> Unit) {
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
                    if (userState.data.isOnboardingCompleted == true) {
                        goToHome()
                    } else {
                        goToIntro()
                    }
                }
            }
        }
    }
}