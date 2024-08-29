package io.nextsense.android.budz.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.PropertyName
import com.google.firebase.firestore.ServerTimestamp

enum class Modality {
    EEEG;

    fun key() = name.lowercase()
}

enum class DataSessionKeys {
    NAME, START_DATETIME, END_DATETIME, SAMPLING_RATE, STREAMING_RATE, HAVE_RAW_DATA;

    fun key() = name.lowercase()
}

data class DataSession(
    @get:PropertyName("name")
    @set:PropertyName("name")
    var name: String? = null,
    @get:PropertyName("start_datetime")
    @set:PropertyName("start_datetime")
    var startDatetime: Timestamp? = null,
    @get:PropertyName("end_datetime")
    @set:PropertyName("end_datetime")
    var endDatetime: Timestamp? = null,
    @get:PropertyName("sampling_rate")
    @set:PropertyName("sampling_rate")
    var samplingRate: Float? = null,
    @get:PropertyName("streaming_rate")
    @set:PropertyName("streaming_rate")
    var streamingRate: Float? = null,
    @get:PropertyName("channel_definitions")
    @set:PropertyName("channel_definitions")
    var channelDefinitions: List<ChannelDefinition>? = null,
    @get:PropertyName("have_raw_data")
    @set:PropertyName("have_raw_data")
    var haveRawData: Boolean? = false,
    @ServerTimestamp
    @get:PropertyName("created_at")
    @set:PropertyName("created_at")
    var createdAt: Timestamp? = null
) {
    @SuppressWarnings("unused")  // Needed for Firestore.
    constructor() : this(null, null, null, null, null, null, false, null)
    constructor(
        name: String,
        startDatetime: Timestamp,
        samplingRate: Float,
        streamingRate: Float,
        channelDefinitions: List<ChannelDefinition>,
        haveRawData: Boolean
    ) : this(name, startDatetime, null, samplingRate, streamingRate, channelDefinitions,
        haveRawData)

    // Optional methods for convenience
    @Exclude
    fun isDataAvailable() = haveRawData

    @Exclude
    fun durationInMillis(): Long? {
        return if (startDatetime != null && endDatetime != null) {
            endDatetime!!.toDate().time - startDatetime!!.toDate().time
        } else {
            null
        }
    }
}