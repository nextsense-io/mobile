package io.nextsense.android.budz.ui.activities

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.budz.Routes
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.AudioSampleType
import io.nextsense.android.budz.ui.screens.BrainEqualizerScreen
import io.nextsense.android.budz.ui.screens.CheckBrainSignalIntroScreen
import io.nextsense.android.budz.ui.screens.CheckConnectionScreen
import io.nextsense.android.budz.ui.screens.ConnnectedScreen
import io.nextsense.android.budz.ui.screens.DeviceSettingsScreen
import io.nextsense.android.budz.ui.screens.FocusScreen
import io.nextsense.android.budz.ui.screens.HomeScreen
import io.nextsense.android.budz.ui.screens.IntroScreen
import io.nextsense.android.budz.ui.screens.LoginScreen
import io.nextsense.android.budz.ui.screens.PrivacyPolicyScreen
import io.nextsense.android.budz.ui.screens.SelectSoundScreen
import io.nextsense.android.budz.ui.screens.SignalVisualizationScreen
import io.nextsense.android.budz.ui.screens.TimedSleepScreen
import io.nextsense.android.budz.ui.theme.BudzTheme
import javax.inject.Inject
import kotlin.system.exitProcess

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject lateinit var airohaDeviceManager: AirohaDeviceManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BudzTheme {
                val navController = rememberNavController()
                NavHost(
                    navController = navController,
                    startDestination = Routes.Login,
                ) {
                    composable<Routes.Login> {
                        LoginScreen(
                            onGoToIntro = {
                                navController.navigate(Routes.Intro) {
                                    popUpTo(Routes.Login) {
                                        inclusive = true
                                    }
                                }
                                navController.clearBackStack<Routes.Login>()
                            },
                            onGoToHome = {
                                navController.navigate(Routes.Home) {
                                    popUpTo(Routes.Login) {
                                        inclusive = true
                                    }
                                }
                                navController.clearBackStack<Routes.Login>()
                            })
                    }
                    composable<Routes.Intro> {
                        IntroScreen(
                            onGoToConnected = {
                                navController.navigate(Routes.Connected) {
                                    popUpTo(Routes.Intro) {
                                        inclusive = true
                                    }
                                }
                                navController.clearBackStack<Routes.Intro>()
                            },
                            onGoToHome = {
                                navController.navigate(Routes.Home) {
                                    popUpTo(Routes.Intro) {
                                        inclusive = true
                                    }
                                }
                                navController.clearBackStack<Routes.Intro>()
                            }
                        )
                    }
                    composable<Routes.Connected> {
                        ConnnectedScreen(
                            onGoToHome = {
                                navController.navigate(Routes.Home) {
                                    popUpTo(Routes.Connected) {
                                        inclusive = true
                                    }
                                }
                                navController.clearBackStack<Routes.Connected>()
                            }
                        )
                    }
                    composable<Routes.Home> {
                        HomeScreen(
                            onSignOut = {
                                navController.navigate(Routes.Login) {
                                    popUpTo(Routes.Home) {
                                        inclusive = true
                                    }
                                }
                                navController.clearBackStack<Routes.Home>()
                            },
                            onGoToPrivacyPolicy = {
                                navController.navigate(Routes.PrivacyPolicy)
                            },
                            onGoToDeviceConnection = {
                                navController.navigate(Routes.CheckConnection)
                            },
                            onGoToFallAsleep = {
                                navController.navigate(Routes.SelectSound(
                                    audioSampleTypeName = AudioSampleType.FALL_ASLEEP.name))
                            },
                            onGoToStayAsleep = {
                                navController.navigate(Routes.SelectSound(
                                    audioSampleTypeName = AudioSampleType.STAY_ASLEEP.name))
                            },
                            onGoToTimedSleep = {
                                navController.navigate(Routes.TimedSleep)
                            },
                            onGoToFocus = {
                                navController.navigate(Routes.Focus)
                            },
                            onGoToDeviceSettings = {
                                navController.navigate(Routes.DeviceSettings)
                            }
                        )
                    }
                    composable<Routes.PrivacyPolicy> {
                        PrivacyPolicyScreen(
                            onGoToHome = {
                                navController.popBackStack()
                            }
                        )
                    }
                    composable<Routes.CheckConnection> {
                        CheckConnectionScreen(
                            onGoToHome = {
                                navController.popBackStack()
                            },
                            onGoToConnectionGuide = {
                                navController.navigate(Routes.DeviceConnection)
                            },
                            onGoToFitGuide = {
                                navController.popBackStack()
                            },
                            onGoToCheckBrainSignal = {
                                navController.navigate(Routes.BrainEqualizer)
                            }
                        )
                    }
                    composable<Routes.BrainEqualizer> {
                        BrainEqualizerScreen(
                            onGoToCheckConnection = {
                                navController.popBackStack()
                            },
                            onGoToConnectionGuide = {
                                navController.navigate(Routes.DeviceConnection)
                            },
                            onGoToFitGuide = {
                                navController.popBackStack()
                            }
                        )
                    }
                    composable<Routes.CheckBrainSignalIntro> {
                        CheckBrainSignalIntroScreen(
                            onGoToCheckConnection = {
                                navController.navigate(Routes.CheckConnection)
                            },
                            onGoToCheckBrainSignal = {
                                navController.navigate(Routes.DeviceConnection)
                            }
                        )
                    }
                    composable<Routes.SelectSound> { backStackEntry ->
                        val selectSound: Routes.SelectSound = backStackEntry.toRoute()
                        SelectSoundScreen(
                            selectSound,
                            onNavigateBack = {
                                navController.popBackStack()
                            }
                        )
                    }
                    composable<Routes.DeviceSettings> {
                        DeviceSettingsScreen(
                            onGoToSignalVisualization = {
                                navController.navigate(Routes.SignalVisualization)
                            }
                        )
                    }
                    composable<Routes.TimedSleep> {
                        TimedSleepScreen(
                            onGoToFallAsleep = {
                                navController.navigate(Routes.SelectSound(audioSampleTypeName =
                                    AudioSampleType.FALL_ASLEEP_TIMED_SLEEP.name))
                            },
                            onGoToStayAsleep = {
                                navController.navigate(Routes.SelectSound(audioSampleTypeName =
                                    AudioSampleType.STAY_ASLEEP_TIMED_SLEEP.name))
                            },
                            onGoToHome = {
                                navController.popBackStack()
                            }
                        )
                    }
                    composable<Routes.Focus> {
                        FocusScreen(
                            onGoToFocusSelection = {
                                navController.navigate(Routes.SelectSound(audioSampleTypeName =
                                    AudioSampleType.FOCUS.name))
                            },
                            onGoToHome = {
                                navController.popBackStack()
                            }
                        )
                    }
                    composable<Routes.SignalVisualization> {
                        SignalVisualizationScreen(
                            onGoToHome = {
                                navController.popBackStack()
                            },
                        )
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        airohaDeviceManager.destroy()
        super.onDestroy()
        exitProcess(0);
    }
}