package io.nextsense.android.budz

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stevdzasan.onetap.OneTapSignInWithGoogle
import com.stevdzasan.onetap.rememberOneTapSignInState
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.budz.manager.GoogleAuth
import io.nextsense.android.budz.ui.theme.BudzTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.last
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val tag = MainActivity::class.java.simpleName
    private val uiScope = CoroutineScope(Dispatchers.Main)
    @Inject lateinit var googleAuth: GoogleAuth

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BudzTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Column {
//                        val state = rememberOneTapSignInState()
//                        OneTapSignInWithGoogle(
//                            state = state,
//                            clientId = stringResource(R.string.web_client_id),
//                            rememberAccount = true,
//                            onTokenIdReceived = { tokenId -> goToHomeActivity(tokenId)},
//                            onDialogDismissed = { message ->
//                                Log.d("LOG", message)
//                            }
//                        )
//                        state.open()
                        val state = rememberOneTapSignInState()
                        OneTapSignInWithGoogle(
                            state = state,
                            clientId = stringResource(R.string.web_client_id),
                            rememberAccount = true,
                            onTokenIdReceived = {
                                uiScope.launch { signIn(tokenId = it) }
                            },
                            onDialogDismissed = {
                                Log.d(tag, "User dismissed login dialog.")
                            }
                        )

                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Button(onClick = { state.open() }) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    if (state.opened) {
                                        CircularProgressIndicator(
                                            color = Color.White
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(text = "Sign in")
                                }
                            }
                        }
                        state.open()
                        Greeting("Android")
                    }
                }
            }
        }
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

    private fun goToHomeActivity() {
        startActivity(Intent(this, HomeActivity::class.java))
        finish()
    }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
    Text(
        text = "Hello $name!",
        modifier = modifier
    )
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    BudzTheme {
        Greeting("Android")
    }
}