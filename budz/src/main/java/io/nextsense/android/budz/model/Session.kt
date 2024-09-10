package io.nextsense.android.budz.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp

enum class SessionKeys {
    ID, START_DATETIME, END_DATETIME, DEVICE_ID, DEVICE_FIRMWARE_VERSION, DEVICE_MAC_ADDRESS,
    DEVICE_VERSION, EARBUDS_CONFIG, MOBILE_APP_VERSION, PROTOCOL_NAME, TIMEZONE, USER_ID;

    fun key() = name.lowercase()
}

enum class ActivityType(val label: String) {
    UNKNOWN("Unknown"),
    EOEC("EOEC"),
    NAP("Nap"),
    SLEEP("Sleep"),
    TV("TV"),
    READING("Reading"),
    MEDITATION("Meditation"),
    THINKING("Thinking"),
    VIDEO_GAME("Video Game"),
    MUSIC("Listening to music"),
    BREATHING("Breathing exercises"),
    WORK_STUDY("Focused Work/Study"),
    NON_SLEEP_DEEP_REST("Non-sleep deep rest"),
    PUZZLE_SOLVING("Puzzle solving"),
    FUTURE_PLANNING("Future thinking / planning"),
    RELAXING("Relaxing");

    companion object {
        fun fromString(value: String): ActivityType {
            return entries.firstOrNull { it.name == value } ?: UNKNOWN
        }

        fun fromLabel(value: String): ActivityType {
            return entries.firstOrNull { it.label == value } ?: UNKNOWN
        }
    }
}

enum class DataQuality(val label: String) {
    UNKNOWN("Unknown"),
    GREAT("Great, Use the data"),
    GOOD("Good, Use the data"),
    FAIR("Maybe, some data issues"),
    POOR("Probably not, data compromised");

    companion object {
        fun fromString(value: String): DataQuality? {
            return entries.firstOrNull { it.name == value }
        }

        fun fromLabel(value: String): DataQuality {
            return entries.firstOrNull { it.label == value } ?: UNKNOWN
        }
    }
}

enum class ToneBud(val label: String) {
    UNKNOWN("Unknown"),
    FIN_PRO("Tone Pro with a fin"),
    FIN_BALANCE("Tone Balance with a fin"),
    FIN_COMFORT("Tone Comfort with a fin"),
    HOOK("Tone with a hook"),
    FIN_LESS("Tone without a fin");

    companion object {
        fun fromString(value: String): ToneBud {
            return entries.firstOrNull { it.name == value } ?: UNKNOWN
        }

        fun fromLabel(value: String): ToneBud {
            return entries.firstOrNull { it.label == value } ?: UNKNOWN
        }
    }
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
    @get:PropertyName("activity_type")
    @set:PropertyName("activity_type")
    var activityType: ActivityType? = null,
    @get:PropertyName("tone_bud")
    @set:PropertyName("tone_bud")
    var toneBud: ToneBud? = null,
    @get:PropertyName("data_quality")
    @set:PropertyName("data_quality")
    var dataQuality: DataQuality? = null,
    @ServerTimestamp
    @get:PropertyName("created_at")
    @set:PropertyName("created_at")
    var createdAt: Timestamp? = null
) {
    @SuppressWarnings("unused")  // Needed for Firestore.
    constructor() : this(null, null, null, null, null, null, null, null, null, null, null)
    constructor(
        startDatetime: Timestamp, deviceId: String, deviceFirmwareVersion: String,
        deviceMacAddress: String, deviceVersion: String, earbudsConfig: String,
        mobileAppVersion: String, protocolName: String, timezone: String, userId: String) :
            this(startDatetime, null, deviceId, deviceFirmwareVersion, deviceMacAddress,
                deviceVersion, earbudsConfig, mobileAppVersion, protocolName, timezone, userId)
}