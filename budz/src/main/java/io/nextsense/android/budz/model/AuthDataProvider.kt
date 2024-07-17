package io.nextsense.android.budz.model

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.firebase.auth.FirebaseUser

enum class AuthState {
    Authenticated, SignedIn, SignedOut;
}

object AuthDataProvider {

    var oneTapSignInResponse by mutableStateOf<OneTapSignInResponse>(AuthResponse.Success(null))

    var anonymousSignInResponse by mutableStateOf<FirebaseSignInResponse>(AuthResponse.Success(null))

    var googleSignInResponse by mutableStateOf<FirebaseSignInResponse>(AuthResponse.Success(null))

    var signOutResponse by mutableStateOf<SignOutResponse>(AuthResponse.Success(false))

    var deleteAccountResponse by mutableStateOf<SignOutResponse>(AuthResponse.Success(false))

    var user by mutableStateOf<FirebaseUser?>(null)

    var isAuthenticated by mutableStateOf(false)

    var isAnonymous by mutableStateOf(false)

    var authState by mutableStateOf(AuthState.SignedOut)
        private set

    fun updateAuthState(user: FirebaseUser?) {
        this.user = user
        isAuthenticated = user != null
        isAnonymous = user?.isAnonymous ?: false

        authState = if (isAuthenticated) {
            if (isAnonymous) AuthState.Authenticated else AuthState.SignedIn
        } else {
            AuthState.SignedOut
        }
    }
}