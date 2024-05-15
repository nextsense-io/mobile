package io.nextsense.android.budz.ui.components

import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthResponse

@Composable
fun GoogleSignIn(
    launch: () -> Unit
) {
    when (val signInWithGoogleResponse = AuthDataProvider.googleSignInResponse) {
        is AuthResponse.Loading -> {
            Log.i("Login:GoogleSignIn", "Loading")
            LoadingCircle()
        }
        is AuthResponse.Success -> signInWithGoogleResponse.data?.let { authResult ->
            Log.i("Login:GoogleSignIn", "Success: $authResult")
            launch()
        }
        is AuthResponse.Failure -> LaunchedEffect(Unit) {
            Log.e("Login:GoogleSignIn", "${signInWithGoogleResponse.e}")
        }
    }
}