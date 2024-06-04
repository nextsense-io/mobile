package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
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

@Composable
fun FocusScreen(focusViewModel: FocusViewModel = hiltViewModel(),
                onGoToFocusSelection: () -> Unit,
                onGoToHome: () -> Unit
) {
    val focusUiState by focusViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleResumeEffect(true) {
        focusViewModel.loadUserSounds()
        onPauseOrDispose {
            focusViewModel.stopFocusing()
        }
    }

    val screenTitle = if (!focusUiState.focusing) stringResource(R.string.app_title) else
        stringResource(R.string.title_time_remaining)

    Scaffold(
        topBar = {
            TopBar(title = screenTitle, isAppTitle = true, showHome = true, showPrivacy = false,
                onNavigationClick = { onGoToHome() })
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
                if (focusUiState.focusing) {
                    SleepCountdownTimer(durationLeft = focusUiState.focusTimeLeft)
                } else {
                    CircleButton(text = stringResource(R.string.label_focus), onClick = {
                        focusViewModel.startFocusing(context)
                    })
                }
                Spacer(modifier = Modifier.weight(1f))
                if (!focusUiState.focusing) {
                    BudzCard {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                stringResource(R.string.label_set_sleep_timer),
                                style = MaterialTheme.typography.displayMedium
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            SimpleButton(name = stringResource(R.string.label_change),
                                enabled = !focusUiState.loading, onClick = {

                                })
                        }
                    }
                }
                if (focusUiState.focusing) {
                    Spacer(modifier = Modifier.height(15.dp))
                    BudzCard {
                        Text(
                            stringResource(R.string.label_focus_sounds),
                            style = MaterialTheme.typography.labelMedium)
                        HorizontalDivider(color = BudzColor.lightPurple)
                        Row(verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("${focusUiState.focusSample?.name}",
                                style = MaterialTheme.typography.displayMedium)
                            Spacer(modifier = Modifier.weight(1f))
                            SimpleButton(name = stringResource(R.string.label_change),
                                enabled = !focusUiState.loading, onClick = {
                                    onGoToFocusSelection()
                                })
                        }
                    }
                    Spacer(modifier = Modifier.weight(1f))
                    WideButton(name = stringResource(R.string.label_end_focus_session), onClick = {
                        focusViewModel.stopFocusing()
                    })
                }
                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}