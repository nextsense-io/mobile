package io.nextsense.android.main.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Text
import io.nextsense.android.main.lucid.R

@Composable
fun PhoneAppCheckingScreen(onInstallAppClick: () -> Unit, onSkipInstallation: () -> Unit) {
    ScalingLazyColumn(
        contentPadding = PaddingValues(top = 45.dp),
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        item {
            Text(
                modifier = Modifier.fillMaxWidth(0.8f),
                text = stringResource(id = R.string.message_missing)
            )
        }
        item {
            Spacer(modifier = Modifier.size(16.dp))
        }
        item {
            Button(modifier = Modifier.fillMaxWidth(0.8f), onClick = onInstallAppClick) {
                Text(stringResource(R.string.install_app))
            }
        }
        item {
            Spacer(modifier = Modifier.size(16.dp))
        }
        item {
            Button(modifier = Modifier.fillMaxWidth(0.8f), onClick = onSkipInstallation) {
                Text(stringResource(R.string.skip_installation))
            }
        }
    }
}