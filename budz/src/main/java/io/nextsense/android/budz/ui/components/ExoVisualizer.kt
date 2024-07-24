package io.nextsense.android.budz.ui.components

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import io.nextsense.android.budz.manager.FFTAudioProcessor

@OptIn(UnstableApi::class)
@Composable
fun ExoVisualizer(audioProcessor: FFTAudioProcessor) {

    // Adds view to Compose
    AndroidView(
        modifier = Modifier.fillMaxSize(), // Occupy the max size in the Compose UI tree
        factory = { context ->
            // Creates view
            ExoVisualizerView(context).apply {
                processor = audioProcessor
            }
        },
        update = { // view ->
            // View's been inflated or state read in this block has been updated
            // Add logic here if necessary

            // As selectedItem is read here, AndroidView will recompose
            // whenever the state changes
            // Example of Compose -> View communication
            // view.processor = audioProcessor
        }
    )
}

/**
 * The visualizer is a view which listens to the FFT changes and forwards it to the band view.
 */
@OptIn(UnstableApi::class)
class ExoVisualizerView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr), Player.Listener, FFTAudioProcessor.FFTListener {

    var processor: FFTAudioProcessor? = null

    private var currentWaveform: FloatArray? = null

    private val bandView = FFTBandView(context, attrs)

    init {
        addView(bandView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
    }

    private fun updateProcessorListenerState(enable: Boolean) {
        if (enable) {
            processor?.listener = this
        } else {
            processor?.listener = null
            currentWaveform = null
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        updateProcessorListenerState(true)
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        updateProcessorListenerState(false)
    }

    override fun onFFTReady(sampleRateHz: Int, channelCount: Int, fft: FloatArray) {
        currentWaveform = fft
        bandView.onFFT(fft)
    }
}