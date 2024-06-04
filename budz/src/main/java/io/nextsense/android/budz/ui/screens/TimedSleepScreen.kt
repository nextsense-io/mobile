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
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleResumeEffect
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.CircleButton
import io.nextsense.android.budz.ui.components.SimpleButton
import io.nextsense.android.budz.ui.components.SleepCountdownTimer
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.WideButton
import io.nextsense.android.budz.ui.theme.BudzColor
import kotlin.time.Duration.Companion.minutes

val sleepDurations = listOf(5.minutes, 10.minutes, 15.minutes, 20.minutes, 30.minutes, 45.minutes,
    60.minutes, 90.minutes, 120.minutes)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimerDropDown(timedSleepViewModel: TimedSleepViewModel, timedSleepState: TimedSleepState) {
    var expanded by remember { mutableStateOf(false) }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = {
            expanded = !expanded
        }
    ) {
        TextField(
            value = stringResource(R.string.label_minutes_choice,
                timedSleepState.sleepTime.inWholeMinutes),
            onValueChange = {},
            readOnly = true,
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.background(color = BudzColor.darkPurple)
        ) {
            sleepDurations.forEach { sleepDuration ->
                DropdownMenuItem(
                    text = { Text(text = stringResource(
                        R.string.label_minutes_choice, sleepDuration.inWholeMinutes),
                        style = MaterialTheme.typography.displayMedium) },
                    onClick = {
                        timedSleepViewModel.changeSleepTime(sleepDuration)
                        expanded = false
                    }
                )
            }
        }
    }
}

@Composable
fun TimedSleepScreen(timedSleepViewModel: TimedSleepViewModel = hiltViewModel(),
                     onGoToFallAsleep: () -> Unit,
                     onGoToStayAsleep: () -> Unit,
                     onGoToHome: () -> Unit
) {
    val homeUiState by timedSleepViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleResumeEffect(true) {
        timedSleepViewModel.loadUserData()
        onPauseOrDispose {
            timedSleepViewModel.stopSleeping()
        }
    }

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true, showHome = true,
                showPrivacy = false, onNavigationClick = { onGoToHome() })
        },
        modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
    ) {
        Surface(modifier = Modifier
            .fillMaxSize()
            .padding(it))
        {
            Column(
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Spacer(modifier = Modifier.weight(1f))
                if (homeUiState.fallingAsleep) {
                    SleepCountdownTimer(durationLeft = homeUiState.sleepTimeLeft)
                } else {
                    CircleButton(text = stringResource(R.string.label_start), onClick = {
                        timedSleepViewModel.startSleeping(context)
                    })
                }
                Spacer(modifier = Modifier.weight(1f))
                if (!homeUiState.fallingAsleep) {
                    BudzCard {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                stringResource(R.string.label_set_sleep_timer),
                                style = MaterialTheme.typography.displayMedium
                            )
                            Spacer(modifier = Modifier.width(30.dp))
                            TimerDropDown(timedSleepViewModel, homeUiState)
                        }
                    }
                }
                Spacer(modifier = Modifier.height(15.dp))
                BudzCard {
                    Text(
                        stringResource(R.string.label_fall_asleep),
                        style = MaterialTheme.typography.labelMedium)
                    HorizontalDivider(color = BudzColor.lightPurple)
                    Row(verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("${homeUiState.fallAsleepSample?.name}",
                            style = MaterialTheme.typography.displayMedium)
                        Spacer(modifier = Modifier.weight(1f))
                        SimpleButton(name = stringResource(R.string.label_change),
                            enabled = !homeUiState.loading, onClick = {
                                onGoToFallAsleep()
                            })
                    }
                }
                Spacer(modifier = Modifier.height(15.dp))
                BudzCard {
                    Text(
                        stringResource(R.string.label_stay_asleep),
                        style = MaterialTheme.typography.labelMedium
                    )
                    HorizontalDivider(color = BudzColor.lightPurple)
                    Row(verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("${homeUiState.stayAsleepSample?.name}",
                            style = MaterialTheme.typography.displayMedium)
                        Spacer(modifier = Modifier.weight(1f))
                        SimpleButton(name = stringResource(R.string.label_change),
                            enabled = !homeUiState.loading, onClick = {
                                onGoToStayAsleep()
                            })
                    }
                }
                if (homeUiState.fallingAsleep) {
                    Spacer(modifier = Modifier.weight(1f))
                    WideButton(name = stringResource(R.string.label_end_timed_sleep), onClick = {
                        timedSleepViewModel.stopSleeping()
                    })
                }
                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}