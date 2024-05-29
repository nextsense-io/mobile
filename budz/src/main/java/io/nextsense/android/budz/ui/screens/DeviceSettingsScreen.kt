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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import io.nextsense.android.budz.ui.components.SimpleButton

@Composable
fun DeviceSettingsScreen(deviceSettingsViewModel: DeviceSettingsViewModel = hiltViewModel()) {
    val deviceSettingsUiState by deviceSettingsViewModel.uiState.collectAsState()

    Column(verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 30.dp)) {
        SimpleButton(name = "Connect and Start Streaming", onClick = {
            deviceSettingsViewModel.connectAndStartStreaming()
        })
        SimpleButton(name = "Disconnect and Stop Streaming", onClick = {
            deviceSettingsViewModel.disconnectAndStopStreaming()
        })
        SimpleButton(name = "Start Streaming", onClick = {
            deviceSettingsViewModel.startStreaming()
        })
        SimpleButton(name = "Stop Streaming", onClick = {
            deviceSettingsViewModel.stopStreaming()
        })
        Spacer(modifier = Modifier.height(20.dp))
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
        Spacer(modifier = Modifier.height(20.dp))
        Text("Last result: ${deviceSettingsUiState.message}")
    }

}