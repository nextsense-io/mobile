package io.nextsense.android.budz.ui.screens

import android.app.Activity
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.auth.api.identity.BeginSignInResult
import com.google.android.gms.common.api.ApiException
import io.nextsense.android.budz.R
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthState
import io.nextsense.android.budz.ui.components.GoogleSignIn
import io.nextsense.android.budz.ui.components.OneTapSignIn
import io.nextsense.android.budz.ui.components.WideButton
import io.nextsense.android.budz.ui.theme.BudzTheme

@Composable
fun LoginScreen(
        onLogin: () -> Unit,
        authViewModel: AuthViewModel = hiltViewModel(),
        loginState: MutableState<Boolean> = mutableStateOf(false)) {

    val launcher = rememberLauncherForActivityResult(
            ActivityResultContracts.StartIntentSenderForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            try {
                val credentials =
                    authViewModel.oneTapClient.getSignInCredentialFromIntent(result.data)
                authViewModel.signInWithGoogle(credentials)
                authViewModel.signInWithDatabase()
            }
            catch (e: ApiException) {
                Log.e("LoginScreen:Launcher","Login One-tap $e")
            }
        }
        else if (result.resultCode == Activity.RESULT_CANCELED){
            Log.e("LoginScreen:Launcher","OneTapClient Canceled")
        }
    }

    fun launch(signInResult: BeginSignInResult) {
        val intent = IntentSenderRequest.Builder(signInResult.pendingIntent.intentSender).build()
        launcher.launch(intent)
    }

    val currentUser = authViewModel.currentUser.collectAsState().value
    AuthDataProvider.updateAuthState(currentUser)
    if (AuthDataProvider.authState == AuthState.SignedIn && !authViewModel.loginDone.value) {
        Log.i("LoginScreen", "Authenticated: ${AuthDataProvider.isAuthenticated}")
        authViewModel.loginDone.value = true
        onLogin()
    }

    Scaffold(
        modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        Surface(modifier = Modifier.fillMaxSize().padding(it)) {
            Column(verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.Start,
                    modifier = Modifier.padding(horizontal = 30.dp)) {
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = stringResource(R.string.label_welcome_1),
                    style = MaterialTheme.typography.labelMedium
                )
                Text(
                    text = stringResource(R.string.label_welcome_2),
                    style = MaterialTheme.typography.titleLarge
                )
                HorizontalDivider(modifier = Modifier.width(100.dp), color = Color.White)
                Spacer(modifier = Modifier.height(80.dp))
                WideButton(
                    name = stringResource(R.string.label_continue_with_google),
                    icon = R.drawable.ic_google,
                    onClick = {
                        authViewModel.oneTapSignIn()
                    },
                )
                Spacer(modifier = Modifier.height(20.dp))
                WideButton(
                    name = stringResource(R.string.label_continue_with_apple),
                    icon = R.drawable.ic_apple,
                    onClick = {
                        // TODO(eric): Implement Apple Sign In
                    },
                )
                Spacer(modifier = Modifier.height(60.dp))
            }
        }
    }

    OneTapSignIn (
        launch = {
            launch(it)
        }
    )

    GoogleSignIn {
        // Dismiss LoginScreen
        loginState.value = false
    }
}

@Preview
@Composable
fun LoginScreenPreview() {
    BudzTheme {
        //LoginScreen()
    }
}