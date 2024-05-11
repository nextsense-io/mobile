package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.AudioSample
import io.nextsense.android.budz.manager.GoogleAuth
import io.nextsense.android.budz.ui.activities.HomeActivity
import io.nextsense.android.budz.ui.activities.SignInActivity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.last
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SignInState(
    val loading: Boolean = false,
    val fallingAsleep: Boolean = false,
    val fallAsleepSample: AudioSample? = null,
    val stayAsleepSample: AudioSample? = null
)

@HiltViewModel
class SignInViewModel @Inject constructor(
    private val googleAuth: GoogleAuth
): ViewModel() {

    private val tag = SignInViewModel::class.java.simpleName
    private val _googleSignInReqCode = 10
    private val _uiState = MutableStateFlow(SignInState())
    private lateinit var _googleSignInClient: GoogleSignInClient

    val uiState: StateFlow<SignInState> = _uiState.asStateFlow()

    fun prepare(context: Context) {
        _googleSignInClient = GoogleSignIn.getClient(context, googleAuth.gso)
    }

    fun signInGoogle(activity: SignInActivity) {
        ActivityCompat.startActivityForResult(activity, _googleSignInClient.signInIntent,
            _googleSignInReqCode, null)
    }

    fun handleSignInResult(resultCode: Int, data: Intent?) {
        val task: Task<GoogleSignInAccount> = GoogleSignIn.getSignedInAccountFromIntent(data)
        handleResult(task)
    }

    private fun handleResult(completedTask: Task<GoogleSignInAccount>) {
        try {
            val account: GoogleSignInAccount? = completedTask.getResult(ApiException::class.java)
            if (account != null) {
                viewModelScope.launch {
                    signIn(account.idToken!!)
                }

            }
        } catch (e: ApiException) {
            Log.w(tag, "signInResult:failed code=" + e.statusCode)
        }
    }

    private suspend fun signIn(tokenId: String) {
        googleAuth.signInFirebase(tokenId).last().let { userSignInState ->
            if (userSignInState is State.Success) {
                Log.d(tag, "User signed in with Firebase.")
                startActivity(Intent(this, HomeActivity::class.java))
            } else {
                Log.d(tag, "User failed to sign in with Firebase: " +
                        userSignInState.toString())
            }
        }
    }

}