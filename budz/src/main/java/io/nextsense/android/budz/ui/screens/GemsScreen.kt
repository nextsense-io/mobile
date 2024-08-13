package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.compose.LocalLifecycleOwner
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.KeepScreenOn
import io.nextsense.android.budz.ui.components.SimpleButton
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent

@Composable
fun GemsScreen(
    viewModel: GemsViewModel = hiltViewModel(),
) {
    LifecycleStartEffect(true) {
        viewModel.startStreaming()
        onStopOrDispose {
            viewModel.stopStreaming()
        }
    }

    DisposableEffect(LocalLifecycleOwner.current.lifecycle) {
        onDispose {
            viewModel.stopCheckingBandPowers()
        }
    }
    KeepScreenOn()
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true,
                leftIconContent = TopBarLeftIconContent.BACK, showPrivacy = false)
        },
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(it)
        ) {
            Column(
                verticalArrangement = Arrangement.Top,
                horizontalAlignment = Alignment.Start,
                modifier = Modifier
                    .padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                val bandPowersText = uiState.bandPowersList.joinToString("\n") {
                    it.entries.joinToString(", ") { (band, power) ->
                        "$band: ${"%.1f".format(power)}"
                    }
                }
                Text(
                    text = bandPowersText,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(16.dp)
                )
                Spacer(modifier = Modifier.height(20.dp))
                SimpleButton(
                    name = if (uiState.testStarted) "Stop Test" else "Start Test",
                    onClick = { viewModel.startStopTest() }
                )
                Spacer(modifier = Modifier.height(20.dp))
                val closestGemLabel = uiState.closestGem ?: ""
                Text(
                    text = "Closest Gem: $closestGemLabel",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(16.dp)
                )
                if (uiState.closestGem != null)
                    Text(
                        text = uiState.closestGem!!.description,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(16.dp)
                    )
            }
        }
    }
}