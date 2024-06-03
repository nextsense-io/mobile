package io.nextsense.android.budz.ui.activities

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.budz.Routes
import io.nextsense.android.budz.ui.screens.DeviceConnectionScreen
import io.nextsense.android.budz.ui.screens.DeviceSettingsScreen
import io.nextsense.android.budz.ui.screens.HomeScreen
import io.nextsense.android.budz.ui.screens.LoginScreen
import io.nextsense.android.budz.ui.screens.SelectFallAsleepSoundScreen
import io.nextsense.android.budz.ui.screens.SelectStayAsleepSoundScreen
import io.nextsense.android.budz.ui.screens.TimedSleepScreen
import io.nextsense.android.budz.ui.theme.BudzTheme

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BudzTheme {
                val navController = rememberNavController()
                NavHost(
                    navController = navController,
                    startDestination = Routes.LoginScreen,
                ) {
                    composable<Routes.LoginScreen> {
                        LoginScreen(onLogin = {
                            navController.navigate(Routes.HomeScreen) {
                                popUpTo(Routes.LoginScreen) {
                                    inclusive = true
                                }
                            }
                            navController.clearBackStack<Routes.LoginScreen>()
                        })
                    }
                    composable<Routes.HomeScreen> {
                        HomeScreen(
                            onSignOut = {
                                navController.navigate(Routes.LoginScreen) {
                                    popUpTo(Routes.HomeScreen) {
                                        inclusive = true
                                    }
                                }
                                navController.clearBackStack<Routes.HomeScreen>()
                            },
                            onGoToDeviceConnection = {
                                navController.navigate(Routes.DeviceConnectionScreen)
                            },
                            onGoToFallAsleep = {
                                navController.navigate(Routes.SelectFallAsleepSoundScreen)
                            },
                            onGoToStayAsleep = {
                                navController.navigate(Routes.SelectStayAsleepSoundScreen)
                            },
                            onGoToTimedSleep = {
                                navController.navigate(Routes.TimedSleepScreen)
                            },
                            onGoToDeviceSettings = {
                                navController.navigate(Routes.DeviceSettingsScreen)
                            }
                        )
                    }
                    composable<Routes.SelectFallAsleepSoundScreen> {
                        SelectFallAsleepSoundScreen(onNavigateBack = {
                            navController.popBackStack()
                        })
                    }
                    composable<Routes.SelectStayAsleepSoundScreen> {
                        SelectStayAsleepSoundScreen(onNavigateBack = {
                            navController.popBackStack()
                        })
                    }
                    composable<Routes.DeviceConnectionScreen> {
                        DeviceConnectionScreen()
                    }
                    composable<Routes.DeviceSettingsScreen> {
                        DeviceSettingsScreen()
                    }
                    composable<Routes.TimedSleepScreen> {
                        TimedSleepScreen(
                            onGoToFallAsleep = {
                                navController.navigate(Routes.SelectFallAsleepSoundScreen)
                            },
                            onGoToStayAsleep = {
                                navController.navigate(Routes.SelectStayAsleepSoundScreen)
                            },
                            onGoToHome = {
                                navController.navigate(Routes.HomeScreen)
                            }
                        )
                    }
                }
            }
        }
    }
}