package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.layout.size
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.theme.BudzColor

enum class TopBarLeftIconContent {
    CONNECTED, DISCONNECTED, BACK, HOME, EMPTY
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TopBar(title: String, isAppTitle: Boolean = false,
           leftIconContent: TopBarLeftIconContent = TopBarLeftIconContent.EMPTY,
           showPrivacy: Boolean = false, onNavigationClick: () -> Unit? = {},
           onPrivacyClick: () -> Unit? = { }) {
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())

    CenterAlignedTopAppBar(
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = Color.Transparent,
            titleContentColor = MaterialTheme.colorScheme.tertiary,
        ),
        title = {
            Text(
                title,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                style = if (isAppTitle) MaterialTheme.typography.titleMedium else
                    MaterialTheme.typography.titleSmall,
            )
        },
        navigationIcon = {
            IconButton(onClick = { onNavigationClick() }) {
                when (leftIconContent) {
                    TopBarLeftIconContent.CONNECTED ->
                        Icon(
                            painter = painterResource(id = R.drawable.ic_connected),
                            contentDescription = null,
                            modifier = Modifier.size(24.dp),
                            tint = Color.Green)
                    TopBarLeftIconContent.DISCONNECTED ->
                        Icon(
                            painter = painterResource(id = R.drawable.ic_disconnected),
                            contentDescription = null,
                            modifier = Modifier.size(24.dp),
                            tint = BudzColor.red)
                    TopBarLeftIconContent.BACK ->
                        Icon(
                            painter = painterResource(id = R.drawable.ic_left_arrow),
                            contentDescription = stringResource(R.string.desc_back_button),
                            modifier = Modifier.size(36.dp),
                            tint = MaterialTheme.colorScheme.tertiary
                        )
                    TopBarLeftIconContent.HOME ->
                        Icon(
                            painter = painterResource(id = R.drawable.ic_home),
                            contentDescription = stringResource(R.string.desc_home_button),
                            modifier = Modifier.size(36.dp),
                            tint = MaterialTheme.colorScheme.tertiary
                        )
                    TopBarLeftIconContent.EMPTY -> TODO()
                }
            }
        },
        actions = {
            if (showPrivacy)
                IconButton(onClick = { onPrivacyClick() }) {
                    Icon(
                        painter = painterResource(id = R.drawable.ic_privacy),
                        contentDescription = stringResource(R.string.desc_privacy_button),
                        modifier = Modifier.size(36.dp),
                        tint = MaterialTheme.colorScheme.tertiary
                    )
                }
        },
        scrollBehavior = scrollBehavior,
    )
}