package io.nextsense.android.budz

import kotlinx.serialization.Serializable

@Serializable
sealed class Routes{
    @Serializable
    data object LoginScreen : Routes()
    @Serializable
    data object HomeScreen : Routes()

    @Serializable
    data object DeviceConnectionScreen : Routes()

    @Serializable
    data object DeviceSettingsScreen : Routes()

    @Serializable
    data object SelectFallAsleepSoundScreen : Routes()

    @Serializable
    data object SelectStayAsleepSoundScreen : Routes()
}