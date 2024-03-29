package io.nextsense.android.main.presentation

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.rememberNavController
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.TimeText
import com.google.android.horologist.compose.ambient.AmbientAware
import com.ramcosta.composedestinations.DestinationsNavHost
import com.ramcosta.composedestinations.navigation.dependency
import io.nextsense.android.main.service.HealthService
import io.nextsense.android.main.theme.LucidWatchTheme

@Composable
fun LucidWatchApp(
    homeViewModel: HomeScreenViewModel = hiltViewModel()
) {
    LucidWatchTheme {
        Scaffold(modifier = Modifier.fillMaxSize(), timeText = { TimeText() }) {
            val uiState by homeViewModel.uiState
            if (uiState == UiState.Supported) {
                AmbientAware {
                    val navController = rememberNavController()
                    DestinationsNavHost(
                        navController = navController,
                        navGraph = NavGraphs.root,
                        startRoute = NavGraphs.root.startRoute,
                        dependenciesContainerBuilder = {
                            dependency(homeViewModel)
                        },
                    )
                }
            } else if (uiState == UiState.NotSupported) {
                NotSupportedScreen()
            }
        }
    }
}

fun startService(context: Context) {
    val intent = Intent(context, HealthService::class.java)
    ContextCompat.startForegroundService(context, intent)
}

fun stopService(context: Context) {
    val intent = Intent(context, HealthService::class.java)
    context.stopService(intent)
}
