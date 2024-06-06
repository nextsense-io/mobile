package io.nextsense.android.budz.ui.components

import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun SimpleButton(name: String, modifier: Modifier = Modifier, enabled: Boolean = true,
                 bigFont: Boolean = false, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier
    ) {
        Text(text = name, style = if (bigFont) MaterialTheme.typography.labelLarge else
            MaterialTheme.typography.labelSmall)
    }
}