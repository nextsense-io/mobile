package io.nextsense.android.budz.ui.screens

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import io.nextsense.android.budz.ui.components.SimpleButton

@Composable
fun SignInScreen(signInViewModel: SignInViewModel = viewModel()) {
    val signInUiState by signInViewModel.uiState.collectAsState()
    val context = LocalContext.current

    val launcher = rememberLauncherForActivityResult(
            ActivityResultContracts.StartActivityForResult()) {
        signInViewModel.handleSignInResult(it.resultCode, it.data)
    }

    Column {
        SimpleButton(name = "Sign in", onClick = {
            signInViewModel.signInGoogle(context)
        })
    }



}