package io.nextsense.android.budz.manager

import com.google.android.gms.auth.api.identity.BeginSignInRequest
import com.google.android.gms.auth.api.identity.SignInClient
import com.google.android.gms.auth.api.identity.SignInCredential
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.common.api.ApiException
import com.google.firebase.Timestamp
import com.google.firebase.auth.AuthCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuth.AuthStateListener
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.auth.GoogleAuthProvider
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.State
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthResponse
import io.nextsense.android.budz.model.DeleteAccountResponse
import io.nextsense.android.budz.model.FirebaseSignInResponse
import io.nextsense.android.budz.model.OneTapSignInResponse
import io.nextsense.android.budz.model.SignOutResponse
import io.nextsense.android.budz.model.User
import io.nextsense.android.budz.model.UserType
import io.nextsense.android.budz.model.UsersRepository
import io.nextsense.android.budz.utils.isWithinPast
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.Date
import javax.inject.Inject
import javax.inject.Named
import javax.inject.Singleton

const val SIGN_IN_REQUEST = "signInRequest"
const val SIGN_UP_REQUEST = "signUpRequest"

object AuthErrors {
    const val CREDENTIAL_ALREADY_IN_USE = "ERROR_CREDENTIAL_ALREADY_IN_USE"
    const val EMAIL_ALREADY_IN_USE = "ERROR_EMAIL_ALREADY_IN_USE"
}

@Singleton
class AuthRepository @Inject constructor(
    private val firebaseAuth: FirebaseAuth,
    private var oneTapClient: SignInClient,
    private var googleSignInClient: GoogleSignInClient,
    private val usersRepository: UsersRepository,

    @Named(SIGN_IN_REQUEST)
    var signInRequest: BeginSignInRequest,
    @Named(SIGN_UP_REQUEST)
    var signUpRequest: BeginSignInRequest,
) {

    var currentUserId: String? = null

    suspend fun signInDatabase() : State<User> {
        if (firebaseAuth.currentUser == null) {
            return State.failed("User is not authenticated")
        }
        val email = firebaseAuth.currentUser!!.email
        val name = firebaseAuth.currentUser!!.displayName
        val userGetState = usersRepository.getUser(firebaseAuth.currentUser!!.uid)
        if (userGetState is State.Success) {
            if (userGetState.data == null) {
                val newUser = User(email = email!!, name = name, type = UserType.consumer,
                    createdAt = Timestamp.now())
                val userAddState = usersRepository.addUser(newUser, firebaseAuth.currentUser!!.uid)
                if (userAddState is State.Success) {
                    currentUserId = firebaseAuth.currentUser!!.uid
                    return State.Success(newUser)
                } else {
                    return State.failed(userAddState.toString())
                }
            } else {
                currentUserId = firebaseAuth.currentUser!!.uid
                return State.Success(userGetState.data)
            }
        } else {
            return State.failed(userGetState.toString())
        }
    }

    fun getAuthState(viewModelScope: CoroutineScope) = callbackFlow {
        val authStateListener = AuthStateListener { authState ->
            authState.currentUser?.let { user ->
                viewModelScope.launch {
                    signInDatabase().let { userState ->
                        if (userState is State.Success) {
                            trySend(authState.currentUser)
                        } else {
                            trySend(null)
                        }
                        channel.close()
                    }
                }
            }
            if (authState.currentUser == null) {
                trySend(null)
                channel.close()
            }
            RotatingFileLogger.get().logi(TAG, "User: ${authState.currentUser?.uid ?: 
                "Not authenticated"}")
        }

        firebaseAuth.addAuthStateListener(authStateListener)

        awaitClose {
            firebaseAuth.removeAuthStateListener(authStateListener)
        }
    }.stateIn(scope=viewModelScope, started=SharingStarted.WhileSubscribed(), initialValue = null)

    suspend fun verifyGoogleSignIn(): Boolean {
        firebaseAuth.currentUser?.let { user ->
            if (user.providerData.map { it.providerId }.contains("google.com")) {
                return try {
                    googleSignInClient.silentSignIn().await()
                    true
                } catch (e: ApiException) {
                    RotatingFileLogger.get().loge(TAG, "Error: ${e.message}")
                    signOut()
                    false
                }
            }
        }
        return false
    }

    suspend fun signInAnonymously(): FirebaseSignInResponse {
        return try {
            val authResult = firebaseAuth.signInAnonymously().await()
            authResult?.user?.let { user ->
                RotatingFileLogger.get().logi(TAG, "FirebaseAuthSuccess: Anonymous UID: " +
                        user.uid
                )
            }
            AuthResponse.Success(authResult)
        } catch (error: Exception) {
            RotatingFileLogger.get().loge(TAG, "FirebaseAuthError: Failed to Sign in anonymously")
            AuthResponse.Failure(error)
        }
    }

    suspend fun onTapSignIn(): OneTapSignInResponse {
        return try {
            val signInResult = oneTapClient.beginSignIn(signInRequest).await()
            AuthResponse.Success(signInResult)
        } catch (e: Exception) {
            try {
                val signUpResult = oneTapClient.beginSignIn(signUpRequest).await()
                AuthResponse.Success(signUpResult)
            } catch(e: Exception) {
                AuthResponse.Failure(e)
            }
        }
    }

    suspend fun signInWithGoogle(credential: SignInCredential): FirebaseSignInResponse {
        val googleCredential = GoogleAuthProvider.getCredential(credential.googleIdToken, null)
        return authenticateUser(googleCredential)
    }

    suspend fun authenticateUser(credential: AuthCredential): FirebaseSignInResponse {
        return if (firebaseAuth.currentUser != null) {
            authLink(credential)
        } else {
            authSignIn(credential)
        }
    }

    suspend fun authSignIn(credential: AuthCredential): FirebaseSignInResponse {
        return try {
            val authResult = firebaseAuth.signInWithCredential(credential).await()
            RotatingFileLogger.get().logi(TAG, "User: ${authResult?.user?.uid}")
            AuthDataProvider.updateAuthState(authResult?.user)
            AuthResponse.Success(authResult)
        }
        catch (error: Exception) {
            AuthResponse.Failure(error)
        }
    }

    suspend fun authLink(credential: AuthCredential): FirebaseSignInResponse {
        return try {
            val authResult = firebaseAuth.currentUser?.linkWithCredential(credential)?.await()
            RotatingFileLogger.get().logi(TAG, "User: ${authResult?.user?.uid}")
            AuthDataProvider.updateAuthState(authResult?.user)
            AuthResponse.Success(authResult)
        }
        catch (error: FirebaseAuthException) {
            when (error.errorCode) {
                AuthErrors.CREDENTIAL_ALREADY_IN_USE,
                AuthErrors.EMAIL_ALREADY_IN_USE -> {
                    RotatingFileLogger.get().loge(TAG, "FirebaseAuthError: authLink(credential:)" +
                            " failed, ${error.message}")
                    return authSignIn(credential)
                }
            }
            AuthResponse.Failure(error)
        }
        catch (error: Exception) {
            AuthResponse.Failure(error)
        }
    }


    suspend fun signOut(): SignOutResponse {
        return try {
            currentUserId = null
            oneTapClient.signOut().await()
            firebaseAuth.signOut()
            AuthResponse.Success(true)
        }
        catch (e: java.lang.Exception) {
            AuthResponse.Failure(e)
        }
    }

    fun checkNeedsReAuth(): Boolean {
        firebaseAuth.currentUser?.metadata?.lastSignInTimestamp?.let { lastSignInDate ->
            return !Date(lastSignInDate).isWithinPast(5)
        }
        return false
    }

    suspend fun authorizeGoogleSignIn(): String? {
        firebaseAuth.currentUser?.let { user ->
            if (user.providerData.map { it.providerId }.contains("google.com")) {
                try {
                    val account = googleSignInClient.silentSignIn().await()
                    return account.idToken
                } catch (e: ApiException) {
                    RotatingFileLogger.get().loge(TAG, "Error: ${e.message}")
                }
            }
        }
        return null
    }

    private suspend fun reauthenticate(googleIdToken: String) {
        val googleCredential = GoogleAuthProvider
            .getCredential(googleIdToken, null)
        firebaseAuth.currentUser?.reauthenticate(googleCredential)?.await()
    }

    suspend fun deleteUserAccount(googleIdToken: String?): DeleteAccountResponse {
        return try {
            firebaseAuth.currentUser?.let { user ->
                if (user.providerData.map { it.providerId }.contains("google.com")) {
                    // Re-authenticate if needed
                    if (checkNeedsReAuth() && googleIdToken != null) {
                        reauthenticate(googleIdToken)
                    }
                    // Revoke
                    googleSignInClient.revokeAccess().await()
                    oneTapClient.signOut().await()
                }
                // Delete firebase user
                firebaseAuth.currentUser?.delete()?.await()
                AuthResponse.Success(true)
            }
            RotatingFileLogger.get().loge(TAG, "FirebaseAuthError: Current user is not available")
            AuthResponse.Success(false)
        }
        catch (e: Exception) {
            RotatingFileLogger.get().loge(TAG, "FirebaseAuthError: Failed to delete user")
            AuthResponse.Failure(e)
        }
    }

    private suspend fun verifyAuthTokenResult(): Boolean {
        return try {
            firebaseAuth.currentUser?.getIdToken(true)?.await()
            true
        } catch (e: Exception) {
            RotatingFileLogger.get().logi(TAG, "Error retrieving id token result. $e")
            false
        }
    }

    companion object {
        private const val TAG = "AuthRepository"
    }
}