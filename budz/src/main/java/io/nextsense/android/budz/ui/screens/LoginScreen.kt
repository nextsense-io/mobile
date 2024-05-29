package io.nextsense.android.budz.ui.screens

import android.app.Activity
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.auth.api.identity.BeginSignInResult
import com.google.android.gms.common.api.ApiException
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthState
import io.nextsense.android.budz.ui.components.GoogleSignIn
import io.nextsense.android.budz.ui.components.OneTapSignIn
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
    if (AuthDataProvider.authState == AuthState.SignedIn) {
        if (!authViewModel.loginDone.value) {
            Log.i("LoginScreen", "Authenticated: ${AuthDataProvider.isAuthenticated}")
            authViewModel.loginDone.value = true
            onLogin()
        }
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.primary
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .padding(16.dp)
                .fillMaxSize()
                .wrapContentSize(Alignment.TopCenter),
            Arrangement.spacedBy(8.dp),
            Alignment.CenterHorizontally
        ) {
//            Image(
//                modifier = Modifier
//                    .fillMaxWidth()
//                    .padding(16.dp)
//                    .weight(1f),
//                painter = painterResource(R.drawable.loginscreen),
//                contentDescription = "app_logo",
//                contentScale = ContentScale.Fit,
//                colorFilter = ColorFilter.tint(color = MaterialTheme.colorScheme.tertiary)
//            )

            Button(
                onClick = {
                    authViewModel.oneTapSignIn()
                },
                modifier = Modifier
                    .size(width = 300.dp, height = 50.dp)
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White
                )
            ) {
//                Image(
//                    painter = painterResource(id = R.drawable.ic_google_logo),
//                    contentDescription = ""
//                )
                Text(
                    text = "Sign in with Google",
                    modifier = Modifier.padding(6.dp),
                    color = Color.Black.copy(alpha = 0.5f)
                )
            }

//            if (AuthDataProvider.authState == AuthState.SignedOut) {
//                Button(
//                    onClick = {
//                        authViewModel.signInAnonymously()
//                    },
//                    modifier = Modifier
//                        .size(width = 200.dp, height = 50.dp)
//                        .padding(horizontal = 16.dp),
//                ) {
//                    Text(
//                        text = "Skip",
//                        modifier = Modifier.padding(6.dp),
//                        color = MaterialTheme.colorScheme.tertiary
//                    )
//                }
//            }
        }
    }

    // AnonymousSignIn()

    OneTapSignIn (
        launch = {
            launch(it)
        }
    )

    GoogleSignIn {
        // Dismiss LoginScreen
        loginState?.let {
            it.value = false
        }
    }

//    LaunchedEffect(true) {
//        authViewModel.checkCurrentAuthState()
//    }
}

@Preview
@Composable
fun LoginScreenPreview() {
    BudzTheme {
        //LoginScreen()
    }
}