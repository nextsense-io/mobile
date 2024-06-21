package io.nextsense.android.budz

import kotlinx.serialization.Serializable

@Serializable
sealed class Routes{
    @Serializable
    data object Login : Routes()

    @Serializable
    data object Intro : Routes()

    @Serializable
    data object Connected : Routes()

    @Serializable
    data object Home : Routes()

    @Serializable
    data object PrivacyPolicy : Routes()

    @Serializable
    data object DeviceConnection : Routes()

    @Serializable
    data object CheckConnection : Routes()

    @Serializable
    data object CheckBrainSignalIntro : Routes()

    @Serializable
    data object DeviceSettings : Routes()

    @Serializable
    data class SelectSound(val audioSampleTypeName: String) : Routes()

    @Serializable
    data object TimedSleep : Routes()

    @Serializable
    data object Focus : Routes()
}