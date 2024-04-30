package io.nextsense.android.main.presentation

import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.ExperimentalWearFoundationApi
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.ScalingLazyListAnchorType
import androidx.wear.compose.foundation.lazy.ScalingLazyListState
import androidx.wear.compose.foundation.rememberActiveFocusRequester
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import io.nextsense.android.main.lucid.R
import kotlinx.coroutines.launch

@OptIn(ExperimentalWearFoundationApi::class)
@Composable
fun PhoneAppCheckingScreen(onInstallAppClick: () -> Unit, onSkipInstallation: () -> Unit) {
    val scalingLazyState = remember { ScalingLazyListState(initialCenterItemIndex = 0) }
    val focusRequester = rememberActiveFocusRequester()
    val coroutineScope = rememberCoroutineScope()
    Scaffold(
        positionIndicator = {
            PositionIndicator(scalingLazyListState = scalingLazyState)
        },
    ) {
        ScalingLazyColumn(contentPadding = PaddingValues(top = 45.dp),
            modifier = Modifier
                .fillMaxWidth()
                .onRotaryScrollEvent { event ->
                    coroutineScope.launch {
                        scalingLazyState.scrollBy(event.verticalScrollPixels)
                        scalingLazyState.animateScrollBy(0f)
                    }
                    false
                }
                .focusRequester(focusRequester)
                .focusable(),
            anchorType = ScalingLazyListAnchorType.ItemStart,
            state = scalingLazyState,
            autoCentering = null,
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center) {
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
                Button(
                    modifier = Modifier.fillMaxWidth(0.8f),
                    onClick = onInstallAppClick,
                ) {
                    Text(
                        stringResource(R.string.install_app),
                        modifier = Modifier.padding(8.dp),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            item {
                Spacer(modifier = Modifier.size(16.dp))
            }
            item {
                Button(modifier = Modifier.fillMaxWidth(0.8f), onClick = onSkipInstallation) {
                    Text(
                        stringResource(R.string.skip_installation),
                        modifier = Modifier.padding(8.dp),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            item {
                Spacer(modifier = Modifier.size(32.dp))
            }
        }
    }
}