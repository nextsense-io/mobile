package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
import com.patrykandpatrick.vico.compose.cartesian.axis.rememberStartAxis
import com.patrykandpatrick.vico.compose.cartesian.fullWidth
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLine
import com.patrykandpatrick.vico.compose.cartesian.layer.rememberLineCartesianLayer
import com.patrykandpatrick.vico.compose.cartesian.rememberCartesianChart
import com.patrykandpatrick.vico.compose.cartesian.rememberVicoScrollState
import com.patrykandpatrick.vico.compose.cartesian.rememberVicoZoomState
import com.patrykandpatrick.vico.compose.common.shader.color
import com.patrykandpatrick.vico.core.cartesian.HorizontalLayout
import com.patrykandpatrick.vico.core.cartesian.Zoom
import com.patrykandpatrick.vico.core.cartesian.data.AxisValueOverrider
import com.patrykandpatrick.vico.core.cartesian.data.CartesianChartModelProducer
import com.patrykandpatrick.vico.core.cartesian.layer.LineCartesianLayer
import com.patrykandpatrick.vico.core.common.data.ExtraStore
import com.patrykandpatrick.vico.core.common.shader.DynamicShader
import io.nextsense.android.budz.ui.theme.BudzColor
import kotlin.math.abs
import kotlin.math.roundToInt

val Double.roundedToNearest: Double
    get() = roundToInt().toDouble()

fun fullyAdaptiveYValues(yFraction: Float, round: Boolean = false): AxisValueOverrider =
    object : AxisValueOverrider {
        private val Double.conditionallyRoundedToNearest
            get() = if (round) roundedToNearest else this

        init {
            require(yFraction > 0f)
        }

        override fun getMinY(minY: Double, maxY: Double, extraStore: ExtraStore): Double {
            val difference = abs(getMaxY(minY, maxY, extraStore) - maxY)
            return (minY - difference).conditionallyRoundedToNearest
        }

        override fun getMaxY(minY: Double, maxY: Double, extraStore: ExtraStore): Double =
            if (minY.roundedToNearest == maxY.roundedToNearest) maxY + 1 else (yFraction * maxY).conditionallyRoundedToNearest
    }

@Composable
fun SignalLineChart(modelProducer: CartesianChartModelProducer, dataPointsSize: Double) {
    CartesianChartHost(
        rememberCartesianChart(
            rememberLineCartesianLayer(
                axisValueOverrider =
                    fullyAdaptiveYValues(yFraction = 1.0f, round = true),
                lineProvider = LineCartesianLayer.LineProvider.series(
                    rememberLine(
                        shader = DynamicShader.color(BudzColor.darkBlue),
                        backgroundShader = null
                    )
                ),
            ),
            horizontalLayout = HorizontalLayout.fullWidth(),
            startAxis = rememberStartAxis(),
            bottomAxis = null,
        ),
        modelProducer,
        zoomState = rememberVicoZoomState(initialZoom = Zoom.x(dataPointsSize),
            zoomEnabled = false),
        scrollState = rememberVicoScrollState(scrollEnabled = false),
        animationSpec = null,
        runInitialAnimation = false,
        modifier = Modifier.height(80.dp).background(Color.Transparent)
    )
}