package io.nextsense.android.budz

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import io.nextsense.android.budz.manager.SoundsManager
import io.nextsense.android.budz.ui.components.AudioSampleList
import io.nextsense.android.budz.ui.components.Title
import io.nextsense.android.budz.ui.theme.BudzTheme

class SelectSoundActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BudzTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Column {
                        Title("Select sound to play when you fall asleep")
                        Row {
                            Spacer(modifier = Modifier.weight(1f))
                            Column {
                                AudioSampleList(context = LocalContext.current,
                                    audioSamples = SoundsManager.stayAsleepSamples
                                )
                            }
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }
    }

    override fun onPause() {
        super.onPause()
        SoundsManager.stopAudioSample()
    }
}