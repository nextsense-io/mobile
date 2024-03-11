package io.nextsense.android.main.presentation

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.flowWithLifecycle
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.TimeText
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.google.android.horologist.compose.ambient.AmbientAware
import io.nextsense.android.main.PERMISSIONS
import io.nextsense.android.main.service.HealthService
import io.nextsense.android.main.theme.LucidWatchTheme
import kotlinx.coroutines.flow.takeWhile
import kotlinx.coroutines.launch

const val MILLISECONDS_PER_SECOND = 1000

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun LucidWatchApp(
    viewModel: HeartRateViewModel = hiltViewModel()
) {
    LucidWatchTheme {
        Scaffold(modifier = Modifier.fillMaxSize(), timeText = { TimeText() }) {
            val enabled by viewModel.enabled.collectAsState()
            val hr by viewModel.hr
            val availability by viewModel.availability
            val uiState by viewModel.uiState
            val context = LocalContext.current
            val coroutineScope = rememberCoroutineScope()
            val lifecycle = LocalLifecycleOwner.current.lifecycle
            if (uiState == UiState.Supported) {
                val multiPermissionsState = rememberMultiplePermissionsState(
                    permissions = PERMISSIONS,
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
                                coroutineScope.launch {
                                    healthService.heartRateFlow.flowWithLifecycle(
                                        lifecycle, Lifecycle.State.STARTED
                                    ).takeWhile { enabled }.collect {
                                        viewModel.onMeasureMessage(it)
                                    }
                                }
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
                    HeartRateScreen(
                        hr = hr, availability = availability, enabled = enabled, onButtonClick = {
                            if (enabled) {
                                viewModel.toggleEnabled()
                                stopService(context)
                            } else {
                                viewModel.toggleEnabled()
                                startService(context)
                            }
                        }, multiPermissionsState = multiPermissionsState
                    )
                }

            } else if (uiState == UiState.NotSupported) {
                NotSupportedScreen()
            }
        }
    }
}

private fun startService(context: Context) {
    val intent = Intent(context, HealthService::class.java)
    ContextCompat.startForegroundService(context, intent)
}

private fun stopService(context: Context) {
    val intent = Intent(context, HealthService::class.java)
    context.stopService(intent)
}
