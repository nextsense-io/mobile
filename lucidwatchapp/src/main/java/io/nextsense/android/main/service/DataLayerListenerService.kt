package io.nextsense.android.main.service

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService
import io.nextsense.android.main.utils.Logger
import io.nextsense.android.main.utils.SharedPreferencesData
import io.nextsense.android.main.utils.SharedPreferencesHelper
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException


class DataLayerListenerService : WearableListenerService() {
    private val logger = Logger(tag = TAG)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        super.onDataChanged(dataEvents)
        logger.log("onDataChanged is triggered")
        val sharedPreferencesHelper = SharedPreferencesHelper(applicationContext)
        dataEvents.forEach { dataEvent ->
            val uri = dataEvent.dataItem.uri
            val map = DataMapItem.fromDataItem(dataEvent.dataItem).dataMap
            when (uri.path) {
                LUCID_NOTIFICATION_SETTINGS_PATH -> {
                    scope.launch {
                        try {
                            val nodeId = uri.host!!
                            if (map.containsKey(SharedPreferencesData.LucidSettings.getKey())) {
                                sharedPreferencesHelper.putString(
                                    key = SharedPreferencesData.LucidSettings.name,
                                    value = map.getDataMap(SharedPreferencesData.LucidSettings.getKey())
                                        .toString()
                                )
                                logger.log(
                                    "Data read successfully from:${nodeId}, data=>${
                                        map.getDataMap(
                                            SharedPreferencesData.LucidSettings.getKey()
                                        )
                                    }"
                                )
                            }
                        } catch (cancellationException: CancellationException) {
                            throw cancellationException
                        } catch (exception: Exception) {
                            logger.log("Data read failed ${exception.message}")
                        }
                    }
                }

                LUCID_LOGIN_STATUS_PATH -> {
                    scope.launch {
                        try {
                            val nodeId = uri.host!!
                            if (map.containsKey(SharedPreferencesData.isUserLogin.getKey())) {
                                sharedPreferencesHelper.putBoolean(
                                    SharedPreferencesData.isUserLogin.name, map.getBoolean(
                                        SharedPreferencesData.isUserLogin.getKey(), false
                                    )
                                )
                                logger.log(
                                    "Data read successfully from:${nodeId}, data=>${
                                        map.getBoolean(
                                            SharedPreferencesData.isUserLogin.getKey(), false
                                        )
                                    }"
                                )
                            }
                        } catch (cancellationException: CancellationException) {
                            throw cancellationException
                        } catch (exception: Exception) {
                            logger.log("Data read failed ${exception.message}")
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