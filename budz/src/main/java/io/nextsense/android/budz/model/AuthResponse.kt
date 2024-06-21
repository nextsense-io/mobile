package io.nextsense.android.budz.model

import com.google.android.gms.auth.api.identity.BeginSignInResult
import com.google.firebase.auth.AuthResult
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.flow.StateFlow

typealias OneTapSignInResponse = AuthResponse<BeginSignInResult>
typealias FirebaseSignInResponse = AuthResponse<AuthResult>
typealias SignOutResponse = AuthResponse<Boolean>
typealias DeleteAccountResponse = AuthResponse<Boolean>
typealias AuthStateResponse = StateFlow<FirebaseUser?>

sealed class AuthResponse<out T> {
    object Loading: AuthResponse<Nothing>()
    data class Success<out T>(val data: T?): AuthResponse<T>()
    data class Failure(val e: Exception): AuthResponse<Nothing>()
}