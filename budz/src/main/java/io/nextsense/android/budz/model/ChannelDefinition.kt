package io.nextsense.android.budz.model

import com.google.firebase.firestore.PropertyName

enum class ChannelType {
    EEEG,
    IMU,
    TIME,
    STATE,
}

data class ChannelDefinition(
    var name: String,
    @get:PropertyName("sampling_rate")
    @set:PropertyName("sampling_rate")
    var samplingRate: Float,
    @get:PropertyName("streaming_rate")
    @set:PropertyName("streaming_rate")
    var streamingRate: Float,
    @get:PropertyName("channel_type")
    @set:PropertyName("channel_type")
    var channelType: String)
