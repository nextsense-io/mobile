package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.R
import kotlin.time.Duration

@Composable
fun SleepCountdownTimer(durationLeft: Duration) {
    Box(modifier = Modifier
        .size(240.dp)
        .border(10.dp, MaterialTheme.colorScheme.primary, CircleShape)
        .clip(CircleShape)
        .background(Color.Transparent)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxSize()) {
            Spacer(modifier = Modifier.weight(1f))
            Row(horizontalArrangement = Arrangement.Center) {
                Text(
                    text = (durationLeft.inWholeSeconds / 60).toString().padStart(2, '0'),
                    style = MaterialTheme.typography.headlineLarge,
                    modifier = Modifier.align(Alignment.Bottom)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = stringResource(id = R.string.label_minutes),
                    style = MaterialTheme.typography.headlineSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
            }
            Row {
                Text(
                    text = (durationLeft.inWholeSeconds % 60).toString().padStart(2, '0'),
                    style = MaterialTheme.typography.headlineLarge,
                    modifier = Modifier.align(Alignment.Bottom)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = stringResource(id = R.string.label_seconds),
                    style = MaterialTheme.typography.headlineSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
            }
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}
