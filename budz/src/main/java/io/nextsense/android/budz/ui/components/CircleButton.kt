package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun CircleButton(text: String, onClick: () -> Unit) {
    Box(modifier = Modifier
            .size(200.dp)
            .border(10.dp, MaterialTheme.colorScheme.primary, CircleShape)
            .clip(CircleShape)
            .background(Color.Transparent)
            .clickable(onClick = onClick),
    ) {
        Text(text = text, style = MaterialTheme.typography.headlineLarge,
            modifier = Modifier.align(Alignment.Center))
    }
}