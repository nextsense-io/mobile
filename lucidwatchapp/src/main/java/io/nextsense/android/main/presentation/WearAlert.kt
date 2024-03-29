package io.nextsense.android.main.presentation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.dialog.Alert
import io.nextsense.android.main.lucid.R

@Composable
fun WearAlert(
    title: String,
    message: String? = null,
    positiveText: String = "OK",
    onPositiveClick: () -> Unit = {},
) {
    Dialog(onDismissRequest = onPositiveClick) {
        Alert(
            title = { Text(title, textAlign = TextAlign.Center) },
            message = {
                Text(
                    text = message ?: "", textAlign = TextAlign.Center
                )
            },
            icon = {
                Icon(
                    imageVector = Icons.Default.WarningAmber,
                    contentDescription = stringResource(id = R.string.not_available),
                    tint = Color.Yellow
                )
            },
            contentPadding = PaddingValues(start = 10.dp, end = 10.dp, top = 24.dp, bottom = 32.dp),
        ) {
            item {
                Chip(
                    label = { Text(positiveText) },
                    onClick = onPositiveClick,
                    colors = ChipDefaults.primaryChipColors(),
                )
            }
        }
    }
}
