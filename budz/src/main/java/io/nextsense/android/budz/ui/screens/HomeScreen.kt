package io.nextsense.android.budz.ui.screens

import android.Manifest
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LifecycleStartEffect
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.ActionButton
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.CircleButton
import io.nextsense.android.budz.ui.components.SimpleButton
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent
import io.nextsense.android.budz.ui.theme.BudzColor

@Composable
fun BatteryLevel(percent: Int?) {
    Row {
        Icon(painter = painterResource(id = R.drawable.ic_battery_40), contentDescription = null)
        Spacer(modifier = Modifier.width(4.dp))
        Text(text = percent?.let { "$it%" } ?: "--%",
            style = MaterialTheme.typography.labelMedium)
    }
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun HomeScreen(
    homeViewModel: HomeViewModel = hiltViewModel(),
    onGoToPrivacyPolicy: () -> Unit,
    onGoToFallAsleep: () -> Unit,
    onGoToStayAsleep: () -> Unit,
    onGoToTimedSleep: () -> Unit,
    onGoToFocus: () -> Unit,
    onGoToDeviceConnection: () -> Unit,
    onGoToDeviceSettings: () -> Unit,
    onSignOut: () -> Unit
) {
    val homeUiState by homeViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleResumeEffect(true) {
        homeViewModel.loadUserSounds()
        onPauseOrDispose {
            homeViewModel.stopSleeping()
        }
    }

    LifecycleStartEffect(true) {
        homeViewModel.connectDeviceIfNeeded()
        homeViewModel.startMonitoring()
        onStopOrDispose {
            homeViewModel.stopMonitoring()
            // TODO(eric): Should not do this if streaming data?
            homeViewModel.stopConnection()
        }
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val bluetoothConnectPermissionsState = rememberMultiplePermissionsState(
            permissions = listOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            )
        )

        LaunchedEffect(bluetoothConnectPermissionsState) {
            bluetoothConnectPermissionsState.launchMultiplePermissionRequest()
        }
    }

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true, showPrivacy = true,
                leftIconContent = if (homeUiState.connected) TopBarLeftIconContent.CONNECTED else
                    TopBarLeftIconContent.DISCONNECTED,
                onPrivacyClick = { onGoToPrivacyPolicy() })
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
                CircleButton(text = if (homeUiState.fallingAsleep) "Pause" else
                        stringResource(R.string.label_sleep), onClick = {
                    if (homeUiState.fallingAsleep) {
                        homeViewModel.stopSleeping()
                    } else {
                        homeViewModel.startSleeping(context)
                    }
                })
                Spacer(modifier = Modifier.height(15.dp))
                BudzCard {
                    Text(stringResource(R.string.label_fall_asleep),
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
                    Text(stringResource(R.string.label_stay_asleep),
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
                Spacer(modifier = Modifier.height(15.dp))
                BudzCard {
                    Row(verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(stringResource(R.string.label_restoration_boost),
                            style = MaterialTheme.typography.labelMedium)
                        Spacer(modifier = Modifier.weight(1f))
                        Switch(checked = homeUiState.restorationBoost, colors =
                            SwitchDefaults.colors(
                                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
                            ),
                            onCheckedChange = {checked ->
                                homeViewModel.setRestorationBoost(checked)
                            })
                    }
                }
                Spacer(modifier = Modifier.height(15.dp))
                BudzCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(stringResource(R.string.label_left),
                            style = MaterialTheme.typography.displayMedium)
                        Spacer(modifier = Modifier.width(5.dp))
                        BatteryLevel(homeUiState.batteryLevel.left)
                        Spacer(modifier = Modifier.weight(1f))
                        VerticalDivider(
                            // color = Color(0xFF434978),
                            color = Color.White,
                            modifier = Modifier
                                .width(1.dp).height(20.dp)
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        Text(stringResource(R.string.label_right),
                            style = MaterialTheme.typography.displayMedium)
                        Spacer(modifier = Modifier.width(5.dp))
                        BatteryLevel(homeUiState.batteryLevel.right)
                    }
                }
                Spacer(modifier = Modifier.height(15.dp))
                BudzCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(stringResource(R.string.label_case),
                            style = MaterialTheme.typography.displayMedium)
                        Spacer(modifier = Modifier.weight(1f))
                        BatteryLevel(homeUiState.batteryLevel.case)
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
                Spacer(modifier = Modifier.height(15.dp))
                Spacer(modifier = Modifier.weight(1f))
                Row(verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    ActionButton(name = stringResource(R.string.label_check_connection),
                        icon = R.drawable.ic_connection,
                        onClick = { onGoToDeviceConnection() })
                    ActionButton(name = stringResource(R.string.label_timed_sleep),
                        icon = R.drawable.ic_clock,
                        onClick = { onGoToTimedSleep() })
                    ActionButton(name = "Device\nsettings", icon = R.drawable.ic_settings,
                        onClick = { onGoToDeviceSettings() })
                    ActionButton(name = stringResource(R.string.label_button_focus),
                        icon= R.drawable.ic_focus, onClick = { onGoToFocus() })
//                    ActionButton(name = "Sign out", icon= R.drawable.ic_focus, onClick = {
//                            homeViewModel.signOut()
//                            onSignOut()
//                        })
                }
            }
        }
    }
}
