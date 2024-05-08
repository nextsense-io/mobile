package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.manager.AudioSample

@Composable
fun AudioSampleList(audioSamples: List<AudioSample>, enabled: Boolean, selected: AudioSample?,
                    playing: Boolean, onSelect: (AudioSample) -> Unit, onStop: () -> Unit) {
    Column(modifier = Modifier.width(200.dp)) {
        audioSamples.forEach { audioSample ->
            val isSelected = audioSample == selected
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween) {
                Text(text = audioSample.name,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal)
                Spacer(modifier = Modifier.weight(1f))
                if (isSelected && playing)
                    SimpleButton(name = "Stop", enabled=enabled, onClick = {
                        onStop()
                    })
                else
                    SimpleButton(name = "Play", enabled=enabled, onClick = {
                        onSelect(audioSample)
                    })
            }
        }
    }
}