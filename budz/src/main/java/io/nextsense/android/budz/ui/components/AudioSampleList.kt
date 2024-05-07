package io.nextsense.android.budz.ui.components

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.manager.AudioSample
import io.nextsense.android.budz.manager.SoundsManager

@Composable
fun AudioSampleList(context: Context, audioSamples: List<AudioSample>) {
    Column(modifier = Modifier.width(200.dp)) {
        audioSamples.forEach { audioSample ->
            Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween) {
                Text(text = audioSample.name)
                Spacer(modifier = Modifier.weight(1f))
                SimpleButton(name = "Play", onClick = {
                    SoundsManager.playAudioSample(context, audioSample.resId)
                })
            }
        }
    }
}