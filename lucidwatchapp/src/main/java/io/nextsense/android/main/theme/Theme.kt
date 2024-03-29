package io.nextsense.android.main.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material.Colors
import androidx.wear.compose.material.MaterialTheme


val MIDNIGHT_BLUE  = Color(0xff0b0d1c)
val DEEP_LAVENDER  = Color(0xff454fb1)

internal val wearColorPalette: Colors = Colors(
    primary = MIDNIGHT_BLUE,
    primaryVariant = Color.LightGray,
    error = Color.Red,
    onPrimary = Color.White,
    onSecondary = DEEP_LAVENDER,
    onError = Color.Black
)

@Composable
fun LucidWatchTheme(
    content: @Composable () -> Unit
) {
    /**
     * Empty theme to customize for your app.
     * See: https://developer.android.com/jetpack/compose/designsystems/custom
     */
    MaterialTheme(
        colors = wearColorPalette,
        content = content
    )
}