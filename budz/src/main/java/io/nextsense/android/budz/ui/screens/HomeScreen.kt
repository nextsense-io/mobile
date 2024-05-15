package io.nextsense.android.budz.ui.screens

import android.content.Intent
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
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.viewmodel.compose.viewModel
import io.nextsense.android.budz.ui.activities.DeviceConnectionActivity
import io.nextsense.android.budz.ui.activities.DeviceSettingsActivity
import io.nextsense.android.budz.ui.activities.MainActivity2
import io.nextsense.android.budz.ui.activities.SelectFallAsleepSoundActivity
import io.nextsense.android.budz.ui.activities.SelectStayAsleepSoundActivity
import io.nextsense.android.budz.ui.activities.SignInActivity
import io.nextsense.android.budz.ui.components.SimpleButton

@Composable
fun HomeScreen(homeViewModel: HomeViewModel = viewModel()) {
    val homeUiState by homeViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleResumeEffect {
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
                context.startActivity(
                    Intent(
                        context,
                        SelectFallAsleepSoundActivity::class.java
                    )
                )
            })
        }
        Row(verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Stay asleep: ${homeUiState.stayAsleepSample?.name}")
            Spacer(modifier = Modifier.weight(1f))
            SimpleButton(name = "Change sound", enabled = !homeUiState.loading, onClick = {
                context.startActivity(
                    Intent(
                        context,
                        SelectStayAsleepSoundActivity::class.java
                    )
                )
            })
        }
        SimpleButton(name = "Check connection", onClick = {
            context.startActivity(
                Intent(
                    context,
                    DeviceConnectionActivity::class.java
                )
            )
        })
        SimpleButton(name = "Test device settings", onClick = {
            context.startActivity(
                Intent(
                    context,
                    DeviceSettingsActivity::class.java
                )
            )
        })
        SimpleButton(name = "Sign out", onClick = {
            homeViewModel.signOut()
            context.startActivity(Intent(context, MainActivity2::class.java))
        })
    }
}