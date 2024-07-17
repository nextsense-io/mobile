package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import io.nextsense.android.budz.R

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
fun PrivacyPolicyPage(showTitle: Boolean = true) {
    Box(modifier = Modifier.fillMaxSize()) {
        Column {
            if (showTitle) {
                Spacer(modifier = Modifier.height(20.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = stringResource(R.string.title_privacy_policy),
                        style = MaterialTheme.typography.titleLarge,
                        textAlign = TextAlign.Center
                    )
                }
            }
            Spacer(modifier = Modifier.height(20.dp))
            Row(modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center) {
                StyledMessage(
                    stringResource(R.string.text_privacy_policy),
                    stringResource(R.string.text_data_connection),
                    stringResource(R.string.text_data_use),
                    stringResource(R.string.text_do_not)
                )
            }
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}