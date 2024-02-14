package io.nextsense.android.main.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material.Colors
import androidx.wear.compose.material.MaterialTheme

internal val wearColorPalette: Colors = Colors(
    primary = Color(48, 49, 51),
    primaryVariant = Color.LightGray,
    error = Color.Red,
    onPrimary = Color.White,
    onSecondary = Color.Black,
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