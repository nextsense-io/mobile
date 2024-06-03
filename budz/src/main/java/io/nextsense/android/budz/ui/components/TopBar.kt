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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TopBar(title: String, isAppTitle: Boolean = false, showHome: Boolean, showPrivacy: Boolean,
           onNavigationClick: () -> Unit, onPrivacyClick: () -> Unit? = { }) {
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
                if (showHome) {
                    Icon(
                        painter = painterResource(id = R.drawable.ic_home),
                        contentDescription = stringResource(R.string.desc_home_button),
                        modifier = Modifier.size(36.dp),
                        tint = MaterialTheme.colorScheme.tertiary
                    )
                } else {
                    Icon(
                        painter = painterResource(id = R.drawable.ic_left_arrow),
                        contentDescription = stringResource(R.string.desc_back_button),
                        modifier = Modifier.size(36.dp),
                        tint = MaterialTheme.colorScheme.tertiary
                    )
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