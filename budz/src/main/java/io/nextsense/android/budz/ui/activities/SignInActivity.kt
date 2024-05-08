package io.nextsense.android.budz.ui.activities

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.core.app.ActivityCompat
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.budz.State
import io.nextsense.android.budz.manager.GoogleAuth
import io.nextsense.android.budz.ui.theme.BudzTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.last
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class SignInActivity : ComponentActivity() {

    private val tag = SignInActivity::class.java.simpleName
    private val uiScope = CoroutineScope(Dispatchers.Main)
    private val googleSignInReqCode = 10

    private lateinit var googleSignInClient: GoogleSignInClient
    @Inject lateinit var googleAuth: GoogleAuth
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        googleSignInClient = GoogleSignIn.getClient(this, googleAuth.gso)
        setContent {
            BudzTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Column {

                    }
                }
            }
        }
    }

    override fun onStart() {
        super.onStart()
//        if (GoogleSignIn.getLastSignedInAccount(this) != null) {
//            startActivity(
//                Intent(
//                    this, HomeActivity::class.java
//                )
//            )
//            finish()
//        }
        signInGoogle()
    }

    private fun signInGoogle() {
        ActivityCompat.startActivityForResult(this, googleSignInClient.signInIntent,
            googleSignInReqCode, null)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == googleSignInReqCode) {
            val task: Task<GoogleSignInAccount> = GoogleSignIn.getSignedInAccountFromIntent(data)
            handleResult(task)
        }
    }

    private fun handleResult(completedTask: Task<GoogleSignInAccount>) {
        try {
            val account: GoogleSignInAccount? = completedTask.getResult(ApiException::class.java)
            if (account != null) {
                updateUI(account)
            }
        } catch (e: ApiException) {
            Toast.makeText(this, e.toString(), Toast.LENGTH_SHORT).show()
        }
    }

    // this is where we update the UI after Google signin takes place
    private fun updateUI(account: GoogleSignInAccount) {
        uiScope.launch {
            signIn(account.idToken!!)
        }
    }

    private fun goToHomeActivity() {
        startActivity(Intent(this, HomeActivity::class.java))
        finish()
    }

    private suspend fun signIn(tokenId: String) {
        googleAuth.signInFirebase(tokenId).last().let { userSignInState ->
            if (userSignInState is State.Success) {
                Log.d(tag, "User signed in with Firebase.")
                goToHomeActivity()
            } else {
                Log.d(tag, "User failed to sign in with Firebase: " +
                        userSignInState.toString())

            }
        }
    }
}