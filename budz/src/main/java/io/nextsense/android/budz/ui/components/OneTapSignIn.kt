package io.nextsense.android.budz.ui.components

import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import com.google.android.gms.auth.api.identity.BeginSignInResult
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthResponse

@Composable
fun OneTapSignIn(
    launch: (result: BeginSignInResult) -> Unit
) {
    when(val oneTapSignInResponse = AuthDataProvider.oneTapSignInResponse) {
        is AuthResponse.Loading ->  {
            Log.i("Login:OneTap", "Loading")
            LoadingCircle()
        }
        is AuthResponse.Success -> oneTapSignInResponse.data?.let { signInResult ->
            LaunchedEffect(signInResult) {
                launch(signInResult)
            }
        }
        is AuthResponse.Failure -> LaunchedEffect(Unit) {
            Log.e("Login:OneTap", "${oneTapSignInResponse.e}")
        }
    }
}
