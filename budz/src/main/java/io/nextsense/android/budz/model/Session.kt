package io.nextsense.android.budz.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp

enum class SessionKeys {
    ID, START_DATETIME, END_DATETIME, DEVICE_ID, DEVICE_FIRMWARE_VERSION, DEVICE_MAC_ADDRESS,
    DEVICE_VERSION, EARBUDS_CONFIG, MOBILE_APP_VERSION, PROTOCOL_NAME, TIMEZONE, USER_ID;

    fun key() = name.lowercase()
}

data class Session(
    @get:PropertyName("start_datetime")
    @set:PropertyName("start_datetime")
    var startDatetime: Timestamp? = null,
    @get:PropertyName("end_datetime")
    @set:PropertyName("end_datetime")
    var endDatetime: Timestamp? = null,
    @get:PropertyName("device_id")
    @set:PropertyName("device_id")
    var deviceId: String? = null,
    @get:PropertyName("device_firmware_version")
    @set:PropertyName("device_firmware_version")
    var deviceFirmwareVersion: String? = null,
    @get:PropertyName("device_mac_address")
    @set:PropertyName("device_mac_address")
    var deviceMacAddress: String? = null,
    @get:PropertyName("device_version")
    @set:PropertyName("device_version")
    var deviceVersion: String? = null,
    @get:PropertyName("earbuds_config")
    @set:PropertyName("earbuds_config")
    var earbudsConfig: String? = null,
    @get:PropertyName("mobile_app_version")
    @set:PropertyName("mobile_app_version")
    var mobileAppVersion: String? = null,
    @get:PropertyName("protocol_name")
    @set:PropertyName("protocol_name")
    var protocolName: String? = null,
    @get:PropertyName("timezone")
    @set:PropertyName("timezone")
    var timezone: String? = null,
    @get:PropertyName("user_id")
    @set:PropertyName("user_id")
    var userId: String? = null,
    @ServerTimestamp
    @get:PropertyName("created_at")
    @set:PropertyName("created_at")
    var createdAt: Timestamp? = null
) {
    // Needed for Firestore.
    constructor() : this(null, null, null, null, null, null, null, null, null, null, null)
    constructor(
        startDatetime: Timestamp, deviceId: String, deviceFirmwareVersion: String,
        deviceMacAddress: String, deviceVersion: String, earbudsConfig: String,
        mobileAppVersion: String, protocolName: String, timezone: String, userId: String) :
            this(startDatetime, null, deviceId, deviceFirmwareVersion, deviceMacAddress,
                deviceVersion, earbudsConfig, mobileAppVersion, protocolName, timezone, userId)
}