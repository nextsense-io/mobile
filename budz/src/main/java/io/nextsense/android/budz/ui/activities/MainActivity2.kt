package io.nextsense.android.budz.ui.activities

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.budz.model.AuthDataProvider
import io.nextsense.android.budz.model.AuthState
import io.nextsense.android.budz.ui.screens.AuthViewModel
import io.nextsense.android.budz.ui.screens.HomeScreen
import io.nextsense.android.budz.ui.screens.LoginScreen
import io.nextsense.android.budz.ui.theme.BudzTheme

@AndroidEntryPoint
class MainActivity2 : ComponentActivity() {

    private val authViewModel by viewModels<AuthViewModel>()
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BudzTheme {
                val currentUser = authViewModel.currentUser.collectAsState().value
                AuthDataProvider.updateAuthState(currentUser)

                Log.i("AuthRepo", "Authenticated: ${AuthDataProvider.isAuthenticated}")
                Log.i("AuthRepo", "User: ${AuthDataProvider.user}")

                if (AuthDataProvider.authState == AuthState.SignedIn) {
                    HomeScreen()
                } else {
                    LoginScreen(authViewModel)
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun HomePreview() {
    BudzTheme {
        HomeScreen(hiltViewModel())
    }
}