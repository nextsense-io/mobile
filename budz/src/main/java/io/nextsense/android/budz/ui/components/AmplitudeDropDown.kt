package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.width
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
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.ui.theme.BudzColor

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AmplitudeDropDown(options: List<Int>, currentSelection: Int, enabled: Boolean,
                  onChange: (amplitude: Int) -> Unit) {
    var expanded by remember { mutableStateOf(false) }

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = {
            if (enabled) {
                expanded = !expanded
            }
        },
        modifier = Modifier.width(100.dp)
    ) {
        TextField(
            value = currentSelection.toString(),
            onValueChange = {},
            readOnly = true,
            trailingIcon = {
                if (enabled) {
                    ExposedDropdownMenuDefaults.TrailingIcon(
                        expanded = expanded,
                    )
                }
            },
            modifier = Modifier.menuAnchor()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier.background(color = BudzColor.darkPurple)
        ) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(text = option.toString(),
                        style = MaterialTheme.typography.displayMedium) },
                    onClick = {
                        onChange(option)
                        expanded = false
                    }
                )
            }
        }
    }
}