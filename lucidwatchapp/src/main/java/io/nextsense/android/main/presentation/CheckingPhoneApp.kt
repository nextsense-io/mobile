package io.nextsense.android.main.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.CircularProgressIndicator
import androidx.wear.compose.material.Text
import io.nextsense.android.main.lucid.R
import io.nextsense.android.main.theme.LucidWatchTheme

@Composable
fun CheckingPhoneAppScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        CircularProgressIndicator()
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = stringResource(id = R.string.checking_phone), textAlign = TextAlign.Center
        )
    }
}

@Preview(
    device = Devices.WEAR_OS_SMALL_ROUND,
    showSystemUi = true
)
@Composable
fun CheckingPhoneAppScreenPreview() {
    LucidWatchTheme {
        CheckingPhoneAppScreen()
    }
}