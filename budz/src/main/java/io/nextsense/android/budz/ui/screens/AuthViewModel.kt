package io.nextsense.android.budz.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.auth.api.identity.SignInClient
import com.google.android.gms.auth.api.identity.SignInCredential
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AuthRepository
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthResponse
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    var authRepository: AuthRepository,
    var oneTapClient: SignInClient
): ViewModel() {

    val currentUser = getAuthState()

    init {
//        getAuthState()
        CoroutineScope(Dispatchers.IO).launch {
            val signedInGoogle = authRepository.verifyGoogleSignIn()
            if (signedInGoogle) {
                authRepository.signInDatabase()
            }
        }
    }

    fun getAuthState() = authRepository.getAuthState(viewModelScope)

//    fun signInAnonymously() = CoroutineScope(Dispatchers.IO).launch {
//        AuthDataProvider.anonymousSignInResponse = AuthResponse.Loading
//        AuthDataProvider.anonymousSignInResponse = authRepository.signInAnonymously()
//    }

    fun oneTapSignIn() = CoroutineScope(Dispatchers.IO).launch {
        AuthDataProvider.oneTapSignInResponse = AuthResponse.Loading
        AuthDataProvider.oneTapSignInResponse = authRepository.onTapSignIn()
    }

    fun signInWithGoogle(credentials: SignInCredential) = CoroutineScope(Dispatchers.IO).launch {
        AuthDataProvider.googleSignInResponse = AuthResponse.Loading
        val response = authRepository.signInWithGoogle(credentials)
        if (response is AuthResponse.Success) {
            val signedInDb = authRepository.signInDatabase()
            if (signedInDb is State.Success) {
                AuthDataProvider.googleSignInResponse = response
            } else {
                AuthDataProvider.googleSignInResponse = AuthResponse.Failure(Exception(
                    "Failed to sign in with database"))
            }
            return@launch
        }
        AuthDataProvider.googleSignInResponse = response
    }

    fun signInWithDatabase() = CoroutineScope(Dispatchers.IO).launch {
        AuthDataProvider.googleSignInResponse = AuthResponse.Loading
        authRepository.signInDatabase()
    }

    fun signOut() = CoroutineScope(Dispatchers.IO).launch {
        AuthDataProvider.signOutResponse = AuthResponse.Loading
        AuthDataProvider.signOutResponse = authRepository.signOut()
    }

    fun checkNeedsReAuth() = CoroutineScope(Dispatchers.IO).launch {
        if (authRepository.checkNeedsReAuth()) {
            // Authorize google sign in
            val idToken = authRepository.authorizeGoogleSignIn()
            if (idToken != null) {
                deleteAccount(idToken)
            }
            else {
                // If failed initiate oneTap sign in flow
                // deleteAccount(googleIdToken:) will be called from oneTap result callback
                oneTapSignIn()
                RotatingFileLogger.get().logi("AuthViewModel:deleteAccount","OneTapSignIn")
            }
        } else {
            deleteAccount(null)
        }
    }

    fun deleteAccount(googleIdToken: String?) = CoroutineScope(Dispatchers.IO).launch {
        RotatingFileLogger.get().logi("AuthViewModel:deleteAccount","Deleting Account...")
        AuthDataProvider.deleteAccountResponse = AuthResponse.Loading
        AuthDataProvider.deleteAccountResponse = authRepository.deleteUserAccount(googleIdToken)
    }
}