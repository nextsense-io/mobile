package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.background
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.theme.BudzColor
import kotlin.time.Duration

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimerDropDown(durationOptions: List<Duration>, currentSelection: Duration,
                  onChange: (duration: Duration) -> Unit) {
    var expanded by remember { mutableStateOf(false) }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = {
            expanded = !expanded
        }
    ) {
        TextField(
            value = stringResource(
                R.string.label_minutes_choice,
                currentSelection.inWholeMinutes),
            onValueChange = {},
            readOnly = true,
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.background(color = BudzColor.darkPurple)
        ) {
            durationOptions.forEach { durationOption ->
                DropdownMenuItem(
                    text = { Text(text = stringResource(
                        R.string.label_minutes_choice, durationOption.inWholeMinutes),
                        style = MaterialTheme.typography.displayMedium) },
                    onClick = {
                        onChange(durationOption)
                        expanded = false
                    }
                )
            }
        }
    }
}