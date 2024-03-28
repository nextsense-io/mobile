package io.nextsense.android.main

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.mutableStateOf
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.lifecycleScope
import androidx.wear.phone.interactions.PhoneTypeHelper
import androidx.wear.remote.interactions.RemoteActivityHelper
import androidx.wear.widget.ConfirmationOverlay
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.CapabilityInfo
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.main.presentation.CheckingPhoneAppScreen
import io.nextsense.android.main.presentation.LucidWatchApp
import io.nextsense.android.main.presentation.PhoneAppCheckingScreen
import io.nextsense.android.main.utils.Logger
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import javax.inject.Inject


@AndroidEntryPoint
class MainActivity : ComponentActivity(), CapabilityClient.OnCapabilityChangedListener {
    @Inject
    lateinit var logger: Logger
    private lateinit var capabilityClient: CapabilityClient
    private lateinit var remoteActivityHelper: RemoteActivityHelper
    private var androidPhoneNodeWithApp = mutableStateOf<Node?>(null)
    private var skipInstallation = mutableStateOf(false)
    private var isCheckingPhone = mutableStateOf(true)

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        capabilityClient = Wearable.getCapabilityClient(this)
        remoteActivityHelper = RemoteActivityHelper(this)
        setContent {
            if (androidPhoneNodeWithApp.value == null && !skipInstallation.value) {
                Log.d(TAG, "Missing")
                if (isCheckingPhone.value) {
                    CheckingPhoneAppScreen()
                } else {
                    PhoneAppCheckingScreen(
                        onInstallAppClick = { openAppInStoreOnPhone() },
                        onSkipInstallation = {
                            skipInstallation.value = true
                        },
                    )
                }
            } else {
                Log.d(TAG, "Installed")
                LucidWatchApp()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        Wearable.getCapabilityClient(this).removeListener(this, CAPABILITY_PHONE_APP)
    }

    override fun onResume() {
        super.onResume()
        Wearable.getCapabilityClient(this).addListener(this, CAPABILITY_PHONE_APP)
        lifecycleScope.launch {
            checkIfPhoneHasApp()
        }
    }

    /*
     * Updates UI when capabilities change (install/uninstall phone app).
     */
    override fun onCapabilityChanged(capabilityInfo: CapabilityInfo) {
        Log.d(TAG, "onCapabilityChanged(): $capabilityInfo")
        androidPhoneNodeWithApp.value = capabilityInfo.nodes.firstOrNull()
    }

    private suspend fun checkIfPhoneHasApp() {
        Log.d(TAG, "checkIfPhoneHasApp()")

        try {
            val capabilityInfo =
                capabilityClient.getCapability(CAPABILITY_PHONE_APP, CapabilityClient.FILTER_ALL)
                    .await()
            Log.d(TAG, "Capability request succeeded.")
            withContext(Dispatchers.Main) {
                androidPhoneNodeWithApp.value = capabilityInfo.nodes.firstOrNull()
            }
        } catch (cancellationException: CancellationException) {
            // Request was cancelled normally
            Log.d(TAG, "Request was cancelled normally.")
        } catch (throwable: Throwable) {
            Log.d(TAG, "Capability request failed to return any results.")
        } finally {
            isCheckingPhone.value = false
        }
    }

    private fun openAppInStoreOnPhone() {
        Log.d(TAG, "openAppInStoreOnPhone()")
        val intent = when (PhoneTypeHelper.getPhoneDeviceType(applicationContext)) {
            PhoneTypeHelper.DEVICE_TYPE_ANDROID -> {
                Log.d(TAG, "\tDEVICE_TYPE_ANDROID")
                // Create Remote Intent to open Play Store listing of app on remote device.
                Intent(Intent.ACTION_VIEW).addCategory(Intent.CATEGORY_BROWSABLE)
                    .setData(Uri.parse(ANDROID_MARKET_APP_URI.plus(packageName)))
            }

            else -> {
                Log.d(TAG, "\tDEVICE_TYPE_ERROR_UNKNOWN")
                return
            }
        }

        lifecycleScope.launch {
            try {
                remoteActivityHelper.startRemoteActivity(intent).await()
                ConfirmationOverlay().showOn(this@MainActivity)
                logger.log("App installation :${intent.data}")
            } catch (cancellationException: CancellationException) {
                // Request was cancelled normally
                throw cancellationException
            } catch (throwable: Throwable) {
                logger.log("App installation error:${throwable.message}")
                ConfirmationOverlay().setType(ConfirmationOverlay.FAILURE_ANIMATION)
                    .showOn(this@MainActivity)
            }
        }
    }

    companion object {
        private const val TAG = "MainActivity"

        // Name of node listed in Phone app's wear.xml.
        private const val CAPABILITY_PHONE_APP = "verify_remote_lucid_phone_app"

        // Links to install mobile app for Android (Play Store).
        private const val ANDROID_MARKET_APP_URI = "market://details?id="
    }
}