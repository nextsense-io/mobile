package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.SimpleButton
import kotlinx.coroutines.launch

@Composable
fun HowToFallAsleepPage() {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        Column {
            Spacer(modifier = Modifier.height(100.dp))
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Spacer(modifier = Modifier.width(80.dp))
                Image(
                    painter = painterResource(id = R.drawable.image_phone),
                    contentDescription = null
                )
                Spacer(modifier = Modifier.weight(1f))
            }
            Spacer(modifier = Modifier.weight(1f))
        }

        Column {
            Spacer(modifier = Modifier.height(165.dp))
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Spacer(modifier = Modifier.width(105.dp))
                Image(
                    painter = painterResource(id = R.drawable.image_sitting_person),
                    contentDescription = null
                )
                Spacer(modifier = Modifier.weight(1f))
            }
            Spacer(modifier = Modifier.weight(1f))
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                Text(
                    text = stringResource(R.string.text_how_it_works),
                    style = MaterialTheme.typography.titleLarge,
                    textAlign = TextAlign.Center
                )
            }
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                Text(
                    text = stringResource(R.string.text_fall_asleep),
                    style = MaterialTheme.typography.titleLarge.copy(fontStyle = FontStyle.Italic),
                    textAlign = TextAlign.Center
                )
            }
            Row {
                Text(
                    text = stringResource(R.string.text_how_fall_asleep_1),
                    style = MaterialTheme.typography.displaySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(16.dp)
                )
            }
            Row {
                Text(
                    text = stringResource(R.string.text_how_fall_asleep_2),
                    style = MaterialTheme.typography.displaySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}

@Composable
fun HowToStayAsleepPage() {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        Column {
            Spacer(modifier = Modifier.weight(1f))
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Spacer(modifier = Modifier.weight(1f))
                Image(
                    painter = painterResource(id = R.drawable.image_bed),
                    contentDescription = null
                )
                Spacer(modifier = Modifier.weight(1f))
            }
            Spacer(modifier = Modifier.weight(1f))
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                Text(
                    text = stringResource(R.string.text_how_it_works),
                    style = MaterialTheme.typography.titleLarge,
                    textAlign = TextAlign.Center
                )
            }
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                Text(
                    text = stringResource(R.string.text_stay_asleep),
                    style = MaterialTheme.typography.titleLarge.copy(fontStyle = FontStyle.Italic),
                    textAlign = TextAlign.Center
                )
            }
            Row {
                Text(
                    text = stringResource(R.string.text_how_stay_asleep_1),
                    style = MaterialTheme.typography.displaySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(16.dp)
                )
            }
            Row {
                Text(
                    text = stringResource(R.string.text_how_stay_asleep_2),
                    style = MaterialTheme.typography.displaySmall,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}

@Composable
fun StyledMessage(format: String, vararg args: Any) {
    val annotatedString = AnnotatedString.Builder().apply {
        var startIndex = 0

        args.forEachIndexed { index, arg ->
            val placeholder = "%${index + 1}\$"
            val placeholderIndex = format.indexOf(placeholder, startIndex)
            val placeholderEndIndex = placeholderIndex + placeholder.length

            withStyle(style = MaterialTheme.typography.bodyMedium.toSpanStyle()) {
                append(format.substring(startIndex, placeholderIndex))
            }

            if (index < 2) {
                withStyle(style = MaterialTheme.typography.bodyMedium.toSpanStyle()
                    .copy(fontWeight = FontWeight.Bold)
                ) {
                    append(arg.toString())
                }
            } else {
                withStyle(style = MaterialTheme.typography.bodyMedium.toSpanStyle()
                    .copy(fontStyle = FontStyle.Italic)
                ) {
                    append(arg.toString())
                }
            }

            startIndex = placeholderEndIndex
        }

        if (startIndex < format.length) {
            withStyle(style = MaterialTheme.typography.bodyMedium.toSpanStyle()) {
                append(format.substring(startIndex))
            }
        }
    }.toAnnotatedString()
    Text(text = annotatedString,
        style = MaterialTheme.typography.displaySmall,
        textAlign = TextAlign.Start,
        modifier = Modifier.padding(16.dp)
    )
}

@Composable
fun PrivacyPolicyPage() {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        Column {
            Spacer(modifier = Modifier.height(20.dp))
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                Text(
                    text = stringResource(R.string.title_privacy_policy),
                    style = MaterialTheme.typography.titleLarge,
                    textAlign = TextAlign.Center
                )
            }
            Spacer(modifier = Modifier.height(20.dp))
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                StyledMessage(stringResource(R.string.text_privacy_policy),
                        stringResource(R.string.text_data_connection),
                        stringResource(R.string.text_data_use),
                        stringResource(R.string.text_do_not)
                    )
            }
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
fun GetYouConnectedPage(introViewModel: IntroViewModel) {
    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        Column {
            Spacer(modifier = Modifier.height(20.dp))
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Start) {
                Text(
                    text = stringResource(R.string.title_get_you_connected),
                    style = MaterialTheme.typography.titleLarge,
                    textAlign = TextAlign.Start,
                    modifier = Modifier.padding(16.dp)
                )
            }
            Spacer(modifier = Modifier.height(20.dp))
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                Text(text = stringResource(R.string.text_get_you_connected),
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Start,
                    modifier = Modifier.padding(16.dp)
                )
            }
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
fun PagerItem(page: Int, introViewModel: IntroViewModel) {
    Surface(modifier = Modifier.fillMaxWidth().fillMaxHeight(0.85f)
            .background(MaterialTheme.colorScheme.background)) {
        when (page) {
            0 -> HowToFallAsleepPage()
            1 -> HowToStayAsleepPage()
            2 -> PrivacyPolicyPage()
            3 -> GetYouConnectedPage(introViewModel)
        }
    }
}

@Composable
fun IntroScreen(
    introViewModel: IntroViewModel = hiltViewModel(),
    onGoToConnected: () -> Unit,
    onGoToHome: () -> Unit
) {
    Box(modifier  = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)) {
        Column(
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.Start
        ) {
            val pageCount = 4
            val coroutineScope = rememberCoroutineScope()
            val pagerState = rememberPagerState(pageCount = { pageCount })
            HorizontalPager(
                beyondViewportPageCount = 2,
                state = pagerState
            ) { pageNumber ->
                PagerItem(page = pageNumber, introViewModel)
            }
            Row(Modifier.height(50.dp).fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                repeat(pageCount) { iteration ->
                    val color = if (pagerState.currentPage == iteration) Color.White else
                        Color.White.copy(alpha = 0.5f)
                    val modifier = if (pagerState.currentPage == iteration) {
                        Modifier.width(40.dp).height(20.dp)
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
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                if (pagerState.currentPage == pageCount - 1) {
                    SimpleButton(name = stringResource(R.string.label_connect), bigFont=true,
                        enabled = !introViewModel.uiState.value.connecting,
                        onClick = {
                            introViewModel.connectBoundDevice(onGoToConnected)
                        })
                } else {
                    SimpleButton(
                        name = stringResource(R.string.label_next),
                        bigFont = true,
                        onClick = {
                            coroutineScope.launch {
                                pagerState.animateScrollToPage(pagerState.currentPage + 1)
                            }
                        })
                }
            }
        }
    }
}