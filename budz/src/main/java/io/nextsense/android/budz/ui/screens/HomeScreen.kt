package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleResumeEffect
import io.nextsense.android.budz.ui.components.SimpleButton

@Composable
fun HomeScreen(
    homeViewModel: HomeViewModel = hiltViewModel(),
    onGoToFallAsleep: () -> Unit,
    onGoToStayAsleep: () -> Unit,
    onGoToDeviceConnection: () -> Unit,
    onGoToDeviceSettings: () -> Unit,
    onSignOut: () -> Unit
) {
    val homeUiState by homeViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleResumeEffect(true) {
        homeViewModel.loadUserSounds()
        onPauseOrDispose {}
    }

    Column(verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 30.dp)) {
        SimpleButton(name = if (homeUiState.fallingAsleep) "Stop Sleeping" else "Sleep", onClick = {
            if (homeUiState.fallingAsleep) {
                homeViewModel.stopSleeping()
            } else {
                homeViewModel.startSleeping(context)
            }
        })
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Fall asleep: ${homeUiState.fallAsleepSample?.name}")
            Spacer(modifier = Modifier.weight(1f))
            SimpleButton(name = "Change sound", enabled = !homeUiState.loading, onClick = {
                onGoToFallAsleep()
            })
        }
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Stay asleep: ${homeUiState.stayAsleepSample?.name}")
            Spacer(modifier = Modifier.weight(1f))
            SimpleButton(name = "Change sound", enabled = !homeUiState.loading, onClick = {
                onGoToStayAsleep()
            })
        }
        SimpleButton(name = "Check connection", onClick = {
            onGoToDeviceConnection()
        })
        SimpleButton(name = "Test device settings", onClick = {
            onGoToDeviceSettings()
        })
        SimpleButton(name = "Sign out", onClick = {
            homeViewModel.signOut()
            onSignOut()
        })
        Text("Connected: ${homeViewModel.uiState.value.connected}")
        Text("Left battery: ${homeViewModel.uiState.value.batteryLevel.left}")
        Text("Right battery: ${homeViewModel.uiState.value.batteryLevel.right}")
    }
}