package io.nextsense.android.budz.ui.screens

import android.Manifest
import android.os.Build
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ButtonColors
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleStartEffect
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.SignalLineChart
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent
import io.nextsense.android.budz.ui.components.WideButton
import io.nextsense.android.budz.ui.theme.BudzColor

@Composable
fun CardNotConnected() {
    BudzCard {
        Column(modifier = Modifier.fillMaxWidth()) {
            Spacer(modifier = Modifier.height(20.dp))
            Text(
                text = stringResource(R.string.label_bluetooth_status),
                style = MaterialTheme.typography.displayMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            Text(
                text = stringResource(R.string.label_disconnected),
                style = MaterialTheme.typography.titleSmall.copy(color = BudzColor.red),
                modifier = Modifier
                    .padding(bottom = 20.dp)
                    .fillMaxWidth(),
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.height(10.dp))
            WideButton(name = stringResource(R.string.label_troubleshoot), onClick = {})
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
fun SoundCheckPage1() {
    Column {
        Text(
            text = stringResource(R.string.text_sound_check_title_1),
            style = MaterialTheme.typography.labelLarge
        )
        Spacer(modifier = Modifier.height(10.dp))
        Text(
            text = stringResource(R.string.text_sound_check_content_1),
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
fun SoundCheckPage2() {
    Column {
        Text(
            text = stringResource(R.string.text_sound_check_title_2),
            style = MaterialTheme.typography.labelLarge
        )
        Spacer(modifier = Modifier.height(10.dp))
        Text(
            text = stringResource(R.string.text_sound_check_content_2),
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
fun SoundCheckPagerItem(page: Int,) {
    Surface(modifier = Modifier
        .fillMaxWidth()
        .fillMaxHeight(0.85f)
        .background(MaterialTheme.colorScheme.background)) {
        when (page) {
            0 -> SoundCheckPage1()
            1 -> SoundCheckPage2()
        }
    }
}

@Composable
fun SoundCheckPager() {
    val pageCount = 2
    val pagerState = rememberPagerState(pageCount = { pageCount })
    HorizontalPager(
        beyondViewportPageCount = 1,
        state = pagerState
    ) { pageNumber ->
        SoundCheckPagerItem(page = pageNumber)
    }
    Spacer(modifier = Modifier.height(10.dp))
    Row(
        Modifier
            .height(50.dp)
            .fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
        repeat(pageCount) { iteration ->
            val color = if (pagerState.currentPage == iteration) Color.White else
                Color.White.copy(alpha = 0.5f)
            val modifier = if (pagerState.currentPage == iteration) {
                Modifier
                    .width(40.dp)
                    .height(20.dp)
            } else {
                Modifier.size(20.dp)
            }
            Box(
                modifier = modifier
                    .padding(4.dp)
                    .clip(CircleShape)
                    .background(color)
            )
        }
    }
}

@Composable
fun BrainSignal(checkConnectionViewModel: CheckConnectionViewModel,
                checkConnectionUiState: CheckConnectionState) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.title_brain_signal),
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        Spacer(modifier = Modifier.height(10.dp))
        BudzCard {
            Row {
                Text(
                    text = stringResource(R.string.label_left_bud),
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
                Spacer(modifier = Modifier.width(5.dp))
                SignalLineChart(modelProducer = checkConnectionViewModel.leftEarChartModelProducer,
                    dataPointsSize = 1000.0,
                    minY = checkConnectionUiState.minY,
                    maxY = checkConnectionUiState.maxY)
            }
        }
        Spacer(modifier = Modifier.height(10.dp))
        BudzCard {
            Row {
                Text(
                    text = stringResource(R.string.label_right_bud),
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
                Spacer(modifier = Modifier.width(5.dp))
                SignalLineChart(checkConnectionViewModel.rightEarChartModelProducer,
                    dataPointsSize = 1000.0,
                    minY = checkConnectionUiState.minY,
                    maxY = checkConnectionUiState.maxY)            }
        }
    }
}

@Composable
fun CardConnected(checkConnectionViewModel: CheckConnectionViewModel,
                  checkConnectionUiState: CheckConnectionState,
                  onGoToCheckBrainSignal: () -> Unit) {
    BudzCard(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.label_bluetooth_status),
            style = MaterialTheme.typography.displayMedium
        )
        Text(
            text = stringResource(R.string.label_connected),
            style = MaterialTheme.typography.titleSmall.copy(color = BudzColor.green),
            modifier = Modifier.padding(bottom = 20.dp)
        )
        HorizontalDivider(color = BudzColor.lightPurple)
        Text(
            text = stringResource(R.string.label_ear_connection),
            style = MaterialTheme.typography.displayMedium,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .padding(top = 10.dp, bottom = 20.dp)
                .fillMaxWidth()
        )
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            BudzCard(modifier = Modifier.background(color = BudzColor.darkBlue)
                    .border(1.dp, color = BudzColor.lightPurple)
                    .padding(10.dp)) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Image(painter = painterResource(id = R.drawable.ic_left_ear),
                        contentDescription = null)
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = stringResource(R.string.label_left),
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.titleSmall
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    TextButton(
                        onClick = {}, enabled = false, colors = ButtonColors(
                            containerColor = BudzColor.green,
                            contentColor = Color.White,
                            disabledContainerColor = BudzColor.green,
                            disabledContentColor = Color.White
                        )
                    ) {
                        Text(stringResource(R.string.label_great))
                    }
                }
            }
            Spacer(modifier = Modifier.width(10.dp))
            BudzCard(modifier = Modifier.background(color = BudzColor.darkBlue)
                    .border(1.dp, color = BudzColor.lightPurple)
                    .padding(10.dp)) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Image(painter = painterResource(id = R.drawable.ic_right_ear),
                        contentDescription = null)
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = stringResource(R.string.label_right),
                        style = MaterialTheme.typography.titleSmall
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    TextButton(
                        onClick = {}, enabled = false, colors = ButtonColors(
                            containerColor = BudzColor.green,
                            contentColor = Color.White,
                            disabledContainerColor = BudzColor.green,
                            disabledContentColor = Color.White
                        )
                    ) {
                        Text(stringResource(R.string.label_great))
                    }
                }
            }
        }
    }
    Column {
        Spacer(modifier = Modifier.height(20.dp))
        // SoundCheckPager()
        BrainSignal(checkConnectionViewModel, checkConnectionUiState)
        Spacer(modifier = Modifier.height(20.dp))
        WideButton(name = stringResource(R.string.label_brain_equalizer),
            onClick = { onGoToCheckBrainSignal() })
    }
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CheckConnectionScreen(
    checkConnectionViewModel: CheckConnectionViewModel = hiltViewModel(),
    onGoToHome: () -> Unit,
    onGoToConnectionGuide: () -> Unit,
    onGoToFitGuide: () -> Unit,
    onGoToCheckBrainSignal: () -> Unit,
) {
    val checkConnectionUiState by checkConnectionViewModel.uiState.collectAsState()

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val bluetoothConnectPermissionsState = rememberMultiplePermissionsState(
            permissions = listOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            )
        )

        LaunchedEffect(bluetoothConnectPermissionsState) {
            bluetoothConnectPermissionsState.launchMultiplePermissionRequest()
        }
    }

    LifecycleStartEffect(true) {
        checkConnectionViewModel.startStreaming()
        onStopOrDispose {
            checkConnectionViewModel.stopStreaming()
        }
    }

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true,
                leftIconContent = TopBarLeftIconContent.BACK, showPrivacy = false,
                onNavigationClick = { onGoToHome() })
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
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                if (checkConnectionUiState.connected) {
                    CardConnected(checkConnectionViewModel, checkConnectionUiState,
                        onGoToCheckBrainSignal)
                } else {
                    CardNotConnected()
                }
            }
        }
    }
}

//@Composable
//fun OldContent() {
//    BudzCard {
//        Column(modifier = Modifier.fillMaxWidth()) {
//            Text(
//                text = stringResource(R.string.label_bluetooth_status),
//                style = MaterialTheme.typography.displayMedium
//            )
//            if (checkConnectionUiState.connected) {
//                Text(
//                    text = stringResource(R.string.label_connected),
//                    style = MaterialTheme.typography.titleSmall.copy(color = BudzColor.green),
//                    modifier = Modifier.padding(bottom = 20.dp)
//                )
//            } else {
//                Text(
//                    text = stringResource(R.string.label_disconnected),
//                    style = MaterialTheme.typography.titleSmall.copy(color = BudzColor.red),
//                    modifier = Modifier.padding(bottom = 20.dp)
//                )
//            }
//        }
//    }
//    Spacer(modifier = Modifier.height(20.dp))
//    TextButton(
//        onClick = { onGoToCheckBrainSignal() }
//    ) {
//        Text(stringResource(R.string.label_check_brain_signal),
//            style = MaterialTheme.typography.labelLarge.copy(color = Color.White))
//    }
//    Spacer(modifier = Modifier.weight(1f))
//    WideButton(
//        name = stringResource(R.string.label_bluetooth_connection_guide),
//        onClick = { onGoToConnectionGuide() },
//        modifier = Modifier.padding(bottom = 20.dp)
//    )
//    WideButton(
//        name = stringResource(R.string.label_fit_guide),
//        onClick = { onGoToFitGuide() }
//    )
//}