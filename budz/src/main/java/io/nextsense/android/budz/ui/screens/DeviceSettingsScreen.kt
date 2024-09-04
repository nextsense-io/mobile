package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import io.nextsense.android.budz.BuildConfig
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.SimpleButton
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent

@Composable
fun DeviceSettingsScreen(
    deviceSettingsViewModel: DeviceSettingsViewModel = hiltViewModel(),
    onGoToSignalVisualization: () -> Unit,
    onGoToGems: () -> Unit,
    onGoToDataCollection: () -> Unit,
    onGoToHome: () -> Unit
) {
    val deviceSettingsUiState by deviceSettingsViewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true,
                leftIconContent = TopBarLeftIconContent.BACK, showPrivacy = false,
                onNavigationClick = { onGoToHome() })
        },
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(it)
        ) {
            Column(
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Spacer(modifier = Modifier.height(20.dp))
                BudzCard {
                    TextField(
                        value = deviceSettingsUiState.soundLoopVolume?.toString() ?: "",
                        onValueChange = { deviceSettingsViewModel.setSoundLoopVolumeField(it) },
                        label = { Text("Sound Loop Volume:") }
                    )
                    Spacer(modifier = Modifier.height(20.dp))
                    Row {
                        SimpleButton(name = "Set Volume (0-4)", onClick = {
                            deviceSettingsViewModel.setSoundLoopVolume(
                                deviceSettingsUiState.soundLoopVolume
                            )
                        })
                        Spacer(modifier = Modifier.weight(1f))
                        SimpleButton(name = "Get Volume", onClick = {
                            deviceSettingsViewModel.getSoundLoopVolume()
                        })
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Row {
                        SimpleButton(name = "Start Sound Loop", onClick = {
                            deviceSettingsViewModel.startSoundLoop()
                        })
                        Spacer(modifier = Modifier.weight(1f))
                        SimpleButton(name = "Stop Sound Loop", onClick = {
                            deviceSettingsViewModel.stopSoundLoop()
                        })
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))
                BudzCard {
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
                    Spacer(modifier = Modifier.height(20.dp))
                    Row {
                        SimpleButton(name = "Set Register", onClick = {
                            deviceSettingsViewModel.setRegister(
                                deviceSettingsUiState.register,
                                deviceSettingsUiState.registerValue
                            )
                        })
                        Spacer(modifier = Modifier.weight(1f))
                        SimpleButton(name = "Get Register", onClick = {
                            deviceSettingsViewModel.getRegister(deviceSettingsUiState.register)
                        })
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Row {
                        SimpleButton(name = "Reset Buds", onClick = {
                            deviceSettingsViewModel.resetBuds()
                        })
                        Spacer(modifier = Modifier.weight(1f))
                        SimpleButton(name = "Power Off Buds", onClick = {
                            deviceSettingsViewModel.powerOffBuds()
                        })
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))
                Text("Last result: ${deviceSettingsUiState.message}")
                Spacer(modifier = Modifier.height(20.dp))
//        SimpleButton(name = "Increase bass gain", onClick = {
//            deviceSettingsViewModel.changeEqualizer(floatArrayOf(8f,8f,8f,8f,0f,0f,0f,0f,0f,0f))
//        })
//        SimpleButton(name = "Normal bass gain", onClick = {
//            deviceSettingsViewModel.changeEqualizer(floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f))
//        })
//        SimpleButton(name = "Lower bass gain", onClick = {
//            deviceSettingsViewModel.changeEqualizer(floatArrayOf(-8f,-8f,-8f,-8f,0f,0f,0f,0f,0f,0f))
//        })
//        SimpleButton(name = "Go to Signal Visualization", onClick = {
//            onGoToSignalVisualization()
//        })
                SimpleButton(name = "Go to Gems", onClick = {
                    onGoToGems()
                })
                Spacer(modifier = Modifier.height(20.dp))
                SimpleButton(name = "Go to Data Collection", onClick = {
                    onGoToDataCollection()
                })
//        Spacer(modifier = Modifier.height(20.dp))
//        Text("Current gains: ${deviceSettingsUiState.gains.joinToString(", ")}")
                Spacer(modifier = Modifier.weight(1f))
                Text("Version: ${BuildConfig.VERSION_NAME}")
            }
        }
    }
}