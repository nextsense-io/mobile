package io.nextsense.android.main.service

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.WearableListenerService
import io.nextsense.android.main.utils.Logger
import io.nextsense.android.main.utils.SharedPreferencesData
import io.nextsense.android.main.utils.SharedPreferencesHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.coroutines.cancellation.CancellationException

class DataLayerListenerService @Inject constructor(
    private val sharedPreferencesHelper: SharedPreferencesHelper, private val logger: Logger
) : WearableListenerService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        super.onDataChanged(dataEvents)
        dataEvents.forEach { dataEvent ->
            val uri = dataEvent.dataItem.uri
            when (uri.path) {
                LUCID_NOTIFICATION_SETTINGS_PATH -> {
                    scope.launch {
                        try {
                            val nodeId = uri.host!!
                            val payload = uri.toString().toByteArray()
                            val map = DataMap.fromByteArray(payload)
                            if (map.containsKey(SharedPreferencesData.LucidSettings.name)) {
                                sharedPreferencesHelper.putString(
                                    SharedPreferencesData.LucidSettings.name,
                                    map.getString(SharedPreferencesData.LucidSettings.name, "")
                                )
                            }
                            logger.log("Data read successfully from:${nodeId}, data=>${map}")
                        } catch (cancellationException: CancellationException) {
                            throw cancellationException
                        } catch (exception: Exception) {
                            logger.log("Data read failed")
                        }
                    }
                }

                LUCID_LOGIN_STATUS_PATH -> {
                    scope.launch {
                        try {
                            val nodeId = uri.host!!
                            val payload = uri.toString().toByteArray()
                            val map = DataMap.fromByteArray(payload)
                            if (map.containsKey(SharedPreferencesData.isUserLogin.name)) {
                                sharedPreferencesHelper.putBoolean(
                                    SharedPreferencesData.isUserLogin.name,
                                    map.getBoolean(SharedPreferencesData.isUserLogin.name, false)
                                )
                            }
                            logger.log("Data read successfully from:${nodeId}, data=>${map}")
                        } catch (cancellationException: CancellationException) {
                            throw cancellationException
                        } catch (exception: Exception) {
                            logger.log("Data read failed")
                        }
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }

    companion object {
        private const val TAG = "DataLayerService"
        const val LUCID_NOTIFICATION_SETTINGS_PATH = "/LucidNotificationSettings"
        const val LUCID_LOGIN_STATUS_PATH = "/LucidLoginStatus"
    }
}