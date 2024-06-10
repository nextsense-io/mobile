package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.TopBar

@Composable
fun CheckBrainSignalIntroScreen(
    onGoToCheckConnection: () -> Unit,
    onGoToCheckBrainSignal: () -> Unit,
) {
    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.title_brain_signal), isAppTitle = false,
                showBack = true, showHome = false, showPrivacy = false,
                onNavigationClick = { onGoToCheckConnection() })
        },
        modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(it)
        ) {
            Column(
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Text(text = stringResource(R.string.text_instructions),
                    style = MaterialTheme.typography.displayMedium,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Start)
                Spacer(modifier = Modifier.height(20.dp))
                Row {
                    Image(
                        painter = painterResource(id = R.drawable.ic_white_checkmark),
                        contentDescription = null
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(text = stringResource(R.string.text_brain_signal_1),
                        style = MaterialTheme.typography.bodyMedium)

                }
                Spacer(modifier = Modifier.height(20.dp))
                Row {
                    Image(
                        painter = painterResource(id = R.drawable.ic_white_checkmark),
                        contentDescription = null
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(text = stringResource(R.string.text_brain_signal_2),
                        style = MaterialTheme.typography.bodyMedium)
                }
                Spacer(modifier = Modifier.height(20.dp))
                Row {
                    Image(
                        painter = painterResource(id = R.drawable.ic_white_checkmark),
                        contentDescription = null
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(text = stringResource(R.string.text_brain_signal_3),
                        style = MaterialTheme.typography.bodyMedium)
                }
                Spacer(modifier = Modifier.height(20.dp))
                Text(text = stringResource(R.string.text_brain_signal_4),
                    style = MaterialTheme.typography.bodyMedium)
                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}