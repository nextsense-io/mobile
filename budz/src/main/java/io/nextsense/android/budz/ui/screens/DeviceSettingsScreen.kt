package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import io.nextsense.android.budz.ui.components.SimpleButton

@Composable
fun DeviceSettingsScreen(deviceSettingsViewModel: DeviceSettingsViewModel = viewModel()) {
    val deviceSettingsUiState by deviceSettingsViewModel.uiState.collectAsState()
    val context = LocalContext.current

    Column(verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 30.dp)) {
        SimpleButton(name = "Increase bass gain", onClick = {
            deviceSettingsViewModel.changeEqualizer(floatArrayOf(8f,8f,8f,8f,0f,0f,0f,0f,0f,0f))
        })
        SimpleButton(name = "Normal bass gain", onClick = {
            deviceSettingsViewModel.changeEqualizer(floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f))
        })
        SimpleButton(name = "Lower bass gain", onClick = {
            deviceSettingsViewModel.changeEqualizer(floatArrayOf(-8f,-8f,-8f,-8f,0f,0f,0f,0f,0f,0f))
        })
        Spacer(modifier = Modifier.height(20.dp))
        Text("Current gains: ${deviceSettingsUiState.gains.joinToString(", ")}")
    }

}