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
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.viewmodel.compose.viewModel
import io.nextsense.android.budz.ui.components.SimpleButton

@Composable
fun DeviceConnectionScreen(deviceConnectionViewModel: DeviceConnectionViewModel = viewModel()) {
    val deviceConnectionUiState by deviceConnectionViewModel.uiState.collectAsState()
    val context = LocalContext.current

//    LifecycleResumeEffect {
//        deviceConnectionViewModel.initPresenter(context)
//        onPauseOrDispose {
//            deviceConnectionViewModel.destroyPresenter()
//        }
//    }

    Column(verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 30.dp)) {
        SimpleButton(name = if (deviceConnectionUiState.connecting) "Connecting..." else
                "Connect", enabled = !deviceConnectionUiState.connecting, onClick = {
            if (!deviceConnectionUiState.connecting) {
                deviceConnectionViewModel.connectBoundDevice()
            }
        })
        Spacer(modifier = Modifier.height(20.dp))
        Text("Device connected: ${deviceConnectionUiState.connected}")
    }
}