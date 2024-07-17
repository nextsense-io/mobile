package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.AudioGroup
import io.nextsense.android.budz.manager.AudioSample
import io.nextsense.android.budz.ui.theme.BudzColor

@Composable
fun AudioSampleList(audioGroups: List<AudioGroup>, enabled: Boolean, selected: AudioSample?,
                    playing: Boolean, onSelect: (AudioSample) -> Unit, onStop: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth()) {
        audioGroups.forEach { audioGroup ->
            Spacer(modifier = Modifier.height(16.dp))
            BudzCard {
                Text(text = audioGroup.name, style = MaterialTheme.typography.labelMedium)
                HorizontalDivider(color = BudzColor.lightPurple)
                audioGroup.samples.forEach { audioSample ->
                    val isSelected = audioSample == selected
                    Row(verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(text = audioSample.name,
                            style = MaterialTheme.typography.displayMedium,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal)
                        Spacer(modifier = Modifier.weight(1f))
                        if (isSelected && playing)
                            IconButton(enabled = enabled, onClick = { onStop() }) {
                                Icon(
                                    painter = painterResource(id = R.drawable.ic_stop),
                                    contentDescription = stringResource(R.string.desc_stop),
                                    modifier = Modifier.size(26.dp),
                                    tint = MaterialTheme.colorScheme.tertiary
                                )
                            }
                        else
                            IconButton(enabled = enabled, onClick = { onSelect(audioSample) }) {
                                Icon(
                                    painter = painterResource(id = R.drawable.ic_play),
                                    contentDescription = stringResource(R.string.desc_play),
                                    modifier = Modifier.size(26.dp),
                                    tint = MaterialTheme.colorScheme.tertiary
                                )
                            }
                    }
                }
            }
        }
    }
}