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
import io.nextsense.android.main.presentation.LucidWatchApp
import io.nextsense.android.main.presentation.PhoneAppCheckingScreen
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext


@AndroidEntryPoint
class MainActivity : ComponentActivity(), CapabilityClient.OnCapabilityChangedListener {
    private lateinit var capabilityClient: CapabilityClient
    private lateinit var remoteActivityHelper: RemoteActivityHelper
    private var androidPhoneNodeWithApp = mutableStateOf<Node?>(null)
    private var skipInstallation = mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        capabilityClient = Wearable.getCapabilityClient(this)
        setContent {
            if (androidPhoneNodeWithApp.value == null && !skipInstallation.value) {
                Log.d(TAG, "Missing")
                PhoneAppCheckingScreen(
                    onInstallAppClick = { openAppInStoreOnPhone() },
                    onSkipInstallation = {
                        skipInstallation.value = true
                    },
                )
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
        // There should only ever be one phone in a node set (much less w/ the correct
        // capability), so I am just grabbing the first one (which should be the only one).
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
                // There should only ever be one phone in a node set (much less w/ the correct
                // capability), so I am just grabbing the first one (which should be the only one).
                androidPhoneNodeWithApp.value = capabilityInfo.nodes.firstOrNull()
            }
        } catch (cancellationException: CancellationException) {
            // Request was cancelled normally
        } catch (throwable: Throwable) {
            Log.d(TAG, "Capability request failed to return any results.")
        }
    }

    private fun openAppInStoreOnPhone() {
        Log.d(TAG, "openAppInStoreOnPhone()")

        val intent = when (PhoneTypeHelper.getPhoneDeviceType(applicationContext)) {
            PhoneTypeHelper.DEVICE_TYPE_ANDROID -> {
                Log.d(TAG, "\tDEVICE_TYPE_ANDROID")
                // Create Remote Intent to open Play Store listing of app on remote device.
                Intent(Intent.ACTION_VIEW).addCategory(Intent.CATEGORY_BROWSABLE)
                    .setData(Uri.parse(ANDROID_MARKET_APP_URI))
            }

            PhoneTypeHelper.DEVICE_TYPE_IOS -> {
                Log.d(TAG, "\tDEVICE_TYPE_IOS")

                // Create Remote Intent to open App Store listing of app on iPhone.
                Intent(Intent.ACTION_VIEW).addCategory(Intent.CATEGORY_BROWSABLE)
                    .setData(Uri.parse(APP_STORE_APP_URI))
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
            } catch (cancellationException: CancellationException) {
                // Request was cancelled normally
                throw cancellationException
            } catch (throwable: Throwable) {
                ConfirmationOverlay().setType(ConfirmationOverlay.FAILURE_ANIMATION)
                    .showOn(this@MainActivity)
            }
        }
    }

    companion object {
        private const val TAG = "MainActivity"

        // Name of capability listed in Phone app's wear.xml.
        // IMPORTANT NOTE: This should be named differently than your Wear app's capability.
        private const val CAPABILITY_PHONE_APP = "verify_remote_lucid_phone_app"

        // Links to install mobile app for both Android (Play Store) and iOS.
        private const val ANDROID_MARKET_APP_URI =
            "market://details?id=io.nextsense.android.main.lucid.dev"

        private const val APP_STORE_APP_URI =
            "https://itunes.apple.com/us/app/android-wear/id986496028?mt=8"
    }
}