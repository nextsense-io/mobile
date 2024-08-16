package io.nextsense.android.budz.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthResponse

@Composable
fun GoogleSignIn(launch: () -> Unit) {
    when (val signInWithGoogleResponse = AuthDataProvider.googleSignInResponse) {
        is AuthResponse.Loading -> {
            RotatingFileLogger.get().logi("Login:GoogleSignIn", "Loading")
            LoadingCircle()
        }
        is AuthResponse.Success -> signInWithGoogleResponse.data?.let { authResult ->
            RotatingFileLogger.get().logi("Login:GoogleSignIn", "Success: $authResult")
            launch()
        }
        is AuthResponse.Failure -> LaunchedEffect(Unit) {
            RotatingFileLogger.get().loge("Login:GoogleSignIn", "${signInWithGoogleResponse.e}")
        }
    }
}