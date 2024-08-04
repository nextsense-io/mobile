package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import io.nextsense.android.budz.BuildConfig
import io.nextsense.android.budz.ui.components.SimpleButton

@Composable
fun DeviceSettingsScreen(
    deviceSettingsViewModel: DeviceSettingsViewModel = hiltViewModel(),
    onGoToSignalVisualization: () -> Unit
) {
    val deviceSettingsUiState by deviceSettingsViewModel.uiState.collectAsState()

    Column(verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 30.dp).verticalScroll(rememberScrollState())) {
        SimpleButton(name = "Connect and Start Streaming", onClick = {
            deviceSettingsViewModel.connectAndStartStreaming()
        })
        SimpleButton(name = "Disconnect and Stop Streaming", onClick = {
            deviceSettingsViewModel.disconnectAndStopStreaming()
        })
        SimpleButton(name = "Start Sound Loop", onClick = {
            deviceSettingsViewModel.startSoundLoop()
        })
        SimpleButton(name = "Stop Sound Loop", onClick = {
            deviceSettingsViewModel.stopSoundLoop()
        })
        SimpleButton(name = "Reset Buds", onClick = {
            deviceSettingsViewModel.resetBuds()
        })
        SimpleButton(name = "Power Off Buds", onClick = {
            deviceSettingsViewModel.powerOffBuds()
        })
        Spacer(modifier = Modifier.height(20.dp))
        TextField(
            value = deviceSettingsUiState.register,
            onValueChange = { deviceSettingsViewModel.setRegisterField(it) },
            label = { Text("Register:") }
        )
        TextField(
            value = deviceSettingsUiState.registerValue,
            onValueChange = { deviceSettingsViewModel.setRegisterValueField(it) },
            label = { Text("Value:") }
        )
        Row {
            SimpleButton(name = "Set Register", onClick = {
                deviceSettingsViewModel.setRegister(deviceSettingsUiState.register,
                    deviceSettingsUiState.registerValue)
            })
            Spacer(modifier = Modifier.weight(1f))
            SimpleButton(name = "Get Register", onClick = {
                deviceSettingsViewModel.getRegister(deviceSettingsUiState.register)
            })
        }
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
        SimpleButton(name = "Go to Signal Visualization", onClick = {
            onGoToSignalVisualization()
        })
        Spacer(modifier = Modifier.height(20.dp))
        Text("Current gains: ${deviceSettingsUiState.gains.joinToString(", ")}")
        Spacer(modifier = Modifier.height(20.dp))
        Text("Last result: ${deviceSettingsUiState.message}")
        Spacer(modifier = Modifier.weight(1f))
        Text("Version: ${BuildConfig.VERSION_NAME}")
    }
}