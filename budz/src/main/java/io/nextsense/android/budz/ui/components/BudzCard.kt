package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun BudzCard(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Card(shape = RoundedCornerShape(10.dp)) {
        Column(modifier = Modifier.padding(vertical = 8.dp, horizontal = 12.dp).then(modifier),
            verticalArrangement = Arrangement.spacedBy(4.dp),
            horizontalAlignment = Alignment.Start) {
            content()
        }
    }
}