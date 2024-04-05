package io.nextsense.android.main.presentation

import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.scrollBy
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.rotary.onRotaryScrollEvent
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.wear.compose.foundation.ExperimentalWearFoundationApi
import androidx.wear.compose.foundation.lazy.ScalingLazyListState
import androidx.wear.compose.foundation.rememberActiveFocusRequester
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.dialog.Alert
import io.nextsense.android.main.lucid.R
import kotlinx.coroutines.launch

@OptIn(ExperimentalWearFoundationApi::class)
@Composable
fun WearAlert(
    title: String,
    message: String? = null,
    positiveText: String = "OK",
    onPositiveClick: () -> Unit = {},
) {
    Dialog(onDismissRequest = onPositiveClick) {
        val scalingLazyState = remember { ScalingLazyListState(initialCenterItemIndex = 0) }
        val focusRequester = rememberActiveFocusRequester()
        val coroutineScope = rememberCoroutineScope()
        Scaffold(
            positionIndicator = {
                PositionIndicator(scalingLazyListState = scalingLazyState)
            },
        ) {
            Alert(
                scrollState = scalingLazyState,
                modifier = Modifier
                    .onRotaryScrollEvent { event ->
                        coroutineScope.launch {
                            scalingLazyState.scrollBy(event.verticalScrollPixels)
                            scalingLazyState.animateScrollBy(0f)
                        }
                        false
                    }
                    .focusRequester(focusRequester)
                    .focusable(),
                title = { Text(title, textAlign = TextAlign.Center) },
                message = {
                    Text(
                        text = message ?: "", textAlign = TextAlign.Center
                    )
                },
                icon = {
                    Icon(
                        imageVector = Icons.Default.WarningAmber,
                        contentDescription = stringResource(id = R.string.not_available),
                        tint = Color.Yellow
                    )
                },
                contentPadding = PaddingValues(
                    start = 10.dp, end = 10.dp, top = 24.dp, bottom = 32.dp
                ),
            ) {
                item {
                    Chip(
                        label = { Text(positiveText) },
                        onClick = onPositiveClick,
                        colors = ChipDefaults.primaryChipColors(),
                    )
                }
            }
        }
    }
}
