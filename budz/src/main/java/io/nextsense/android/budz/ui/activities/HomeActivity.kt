package io.nextsense.android.budz.ui.activities

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.budz.ui.components.SimpleButton
import io.nextsense.android.budz.ui.theme.BudzTheme

@AndroidEntryPoint
class HomeActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val viewModel: HomeViewModel by viewModels()

        setContent {
            BudzTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    Column {
                        Greeting("Home!")
                        val context = LocalContext.current
                        SimpleButton(name = "Change fall asleep sound", onClick = {
                            startActivity(
                                Intent(
                                    context,
                                    SelectStayAsleepSoundActivity::class.java
                                )
                            )
                        })
                        SimpleButton(name = "Change stay sleeping sound", onClick = {
                            startActivity(
                                Intent(
                                    context,
                                    SelectStayAsleepSoundActivity::class.java
                                )
                            )
                        })
                        SimpleButton(name = "Sign out", onClick = {
                            viewModel.signOut()
                            startActivity(Intent(context, SignInActivity::class.java))
                        })
                    }
                }
                    }
        }
    }
}