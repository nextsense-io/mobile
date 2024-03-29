package io.nextsense.android.main.presentation

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.IBinder
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.TimeText
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.MultiplePermissionsState
import com.google.accompanist.permissions.PermissionState
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.google.android.horologist.compose.ambient.AmbientAware
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.ramcosta.composedestinations.navigation.EmptyDestinationsNavigator
import io.nextsense.android.main.PERMISSIONS
import io.nextsense.android.main.PERMISSIONS_TIRAMISU
import io.nextsense.android.main.lucid.R
import io.nextsense.android.main.presentation.destinations.ExitConfirmationDestination
import io.nextsense.android.main.service.HealthService
import io.nextsense.android.main.theme.DEEP_LAVENDER
import io.nextsense.android.main.theme.MIDNIGHT_BLUE
import io.nextsense.android.main.utils.LucidNavGraph

@OptIn(ExperimentalPermissionsApi::class)
@LucidNavGraph(start = true)
@Destination
@Composable
fun HomeScreen(
    navigator: DestinationsNavigator, viewModel: HomeScreenViewModel
) {
    Scaffold(modifier = Modifier.fillMaxSize(), timeText = { TimeText() }) {
        val enabled by viewModel.enabled.collectAsState()
        val uiState by viewModel.uiState
        val context = LocalContext.current
        val isUserLogin by viewModel.isUserLogin.collectAsState()
        val isRealitySettingCreated =
            viewModel.isRealitySettingCreated.collectAsState().value.isNotBlank()
        var showAlert by remember { mutableStateOf(false) }
        if (showAlert) {
            WearAlert(
                title = "Setup Required",
                message = "You will need to configure notifications on phone app before you start dreaming.",
                positiveText = "Dismiss",
                onPositiveClick = { showAlert = false }
            )
        }
        if (uiState == UiState.Supported) {
            val multiPermissionsState = rememberMultiplePermissionsState(
                permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) PERMISSIONS_TIRAMISU else PERMISSIONS,
                onPermissionsResult = { result ->
                    val granted = result.all { it.value }
                    if (granted) {
                        viewModel.toggleEnabled()
                        startService(context)
                    }
                },
            )
            if (!enabled) {
                DisposableEffect(key1 = context) {
                    val intent = Intent(context, HealthService::class.java)
                    val serviceConnection = object : ServiceConnection {
                        override fun onServiceConnected(
                            name: ComponentName?, service: IBinder?
                        ) {
                            val binder = service as HealthService.HealthServiceBinder
                            val healthService: HealthService = binder.getService()
                            val serviceRunning = healthService.serviceRunningInForeground
                            viewModel.enabled.value = serviceRunning
                            viewModel.availability.value = healthService.availability.value
                        }

                        override fun onServiceDisconnected(name: ComponentName?) {
                            // Handle service disconnection if needed
                        }
                    }
                    context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
                    // Unbind the service when the composable is removed from the composition
                    onDispose {
                        try {
                            context.unbindService(serviceConnection)
                        } catch (e: IllegalArgumentException) {
                            // Handle unbindService exception if needed
                        }
                    }
                }
            }
            AmbientAware {
                if (enabled) {
                    ExitDreaming(viewModel = viewModel, navigator = navigator) {
                        viewModel.toggleEnabled()
                        stopService(context)
                    }
                } else {
                    StartDreaming(
                        onButtonClick = {
                            if (isUserLogin && isRealitySettingCreated) {
                                viewModel.toggleEnabled()
                                startService(context)
                            } else {
                                showAlert = true
                            }
                        },
                        multiPermissionsState = multiPermissionsState,
                    )
                }

            }

        } else if (uiState == UiState.NotSupported) {
            NotSupportedScreen()
        }
    }
}

@Composable
fun ExitDreaming(
    navigator: DestinationsNavigator,
    viewModel: HomeScreenViewModel,
    onExit: () -> Unit,
) {
    val onExitEvent by viewModel.onExitEvent
    if (onExitEvent == UiState.Exit) {
        onExit()
        viewModel.onExitEvent.value = UiState.Startup
    }
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(color = MIDNIGHT_BLUE)
            .padding(horizontal = 32.dp, vertical = 16.dp)
    ) {
        Spacer(modifier = Modifier.padding(16.dp))
        Text(
            text = "Lucid Reality is in dream mode", modifier = Modifier
        )
        Spacer(modifier = Modifier.padding(8.dp))
        Text(
            text = "EXIT",
            modifier = Modifier
                .fillMaxWidth()
                .border(
                    width = 1.dp, DEEP_LAVENDER, shape = RoundedCornerShape(15.dp)
                )
                .padding(16.dp)
                .clickable {
                    navigator.navigate(ExitConfirmationDestination)
                },
            textAlign = TextAlign.Center,
        )
    }
}

@Preview(device = Devices.WEAR_OS_SMALL_ROUND, showBackground = false, showSystemUi = true)
@Composable
private fun ExitDreamingPreview() {
    ExitDreaming(navigator = EmptyDestinationsNavigator, viewModel = hiltViewModel()) {}
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun StartDreaming(
    onButtonClick: () -> Unit, multiPermissionsState: MultiplePermissionsState
) {
    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        Image(
            painter = painterResource(id = R.drawable.home_bg),
            contentDescription = "BackgroundGradient",
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.FillBounds
        )
        Box(
            modifier = Modifier
                .wrapContentHeight()
                .align(Alignment.Center)
                .fillMaxWidth(0.7f)
                .clickable {
                    if (multiPermissionsState.allPermissionsGranted) {
                        onButtonClick()
                    } else {
                        multiPermissionsState.launchMultiplePermissionRequest()
                    }
                },
            contentAlignment = Alignment.Center,
        ) {
            Image(
                painter = painterResource(id = R.drawable.btn_start),
                contentDescription = null, // Provide content description if needed
                contentScale = ContentScale.Fit
            )
            Text(
                text = "Start Dreaming".uppercase(),
                modifier = Modifier.padding(16.dp),
                textAlign = TextAlign.Center
            )
        }
    }
}

@OptIn(ExperimentalPermissionsApi::class)
@Preview(device = Devices.WEAR_OS_SMALL_ROUND, showBackground = false, showSystemUi = true)
@Composable
private fun StartDreamingPreview() {
    val multiPermissionsState = object : MultiplePermissionsState {
        override val allPermissionsGranted: Boolean
            get() = false
        override val permissions: List<PermissionState>
            get() = listOf()
        override val revokedPermissions: List<PermissionState>
            get() = listOf()
        override val shouldShowRationale: Boolean
            get() = false

        override fun launchMultiplePermissionRequest() {
        }
    }
    StartDreaming(
        onButtonClick = {}, multiPermissionsState = multiPermissionsState
    )
}

@Composable
@Destination
fun ExitConfirmation(
    viewModel: HomeScreenViewModel, navigator: DestinationsNavigator
) {
    ScalingLazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(color = MaterialTheme.colors.primary)
            .padding(horizontal = 24.dp, vertical = 20.dp)
    ) {
        item {
            Text(
                text = "Are you sure you want to exit dream mode?",
                modifier = Modifier.padding(bottom = 8.dp)
            )
        }
        item {
            Box(
                modifier = Modifier
                    .wrapContentHeight()
                    .fillMaxWidth()
                    .clickable {
                        viewModel.onExit()
                        navigator.navigateUp()
                    },
                contentAlignment = Alignment.Center,
            ) {
                Image(
                    painter = painterResource(id = R.drawable.btn_start),
                    contentDescription = null,
                    contentScale = ContentScale.Fit
                )
                Text(
                    text = "Yes, I'm \nawake".uppercase(), modifier = Modifier.padding(top = 4.dp)
                )
            }
        }
        item {
            Text(
                text = "No, I want to keep dreaming".uppercase(),
                modifier = Modifier
                    .padding(top = 4.dp)
                    .fillMaxWidth()
                    .border(
                        width = 1.dp, DEEP_LAVENDER, shape = RoundedCornerShape(15.dp)
                    )
                    .padding(16.dp)
                    .clickable { navigator.navigateUp() },
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Preview(device = Devices.WEAR_OS_SMALL_ROUND, showBackground = false, showSystemUi = true)
@Composable
private fun ExitConfirmationPreview() {
    ExitConfirmation(navigator = EmptyDestinationsNavigator, viewModel = hiltViewModel())
}