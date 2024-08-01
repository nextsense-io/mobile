package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
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

fun Double.nearValue(other: Double) : Boolean {
    return (abs(this - other) < 0.01)
}

fun fullyAdaptiveYValues(): AxisValueOverrider =
    object : AxisValueOverrider {
        override fun getMinY(minY: Double, maxY: Double, extraStore: ExtraStore) =
            if (minY.nearValue(maxY)) minY - 1 else minY

        override fun getMaxY(minY: Double, maxY: Double, extraStore: ExtraStore) =
            if (minY.nearValue(maxY)) maxY + 1 else maxY
    }

@Composable
fun SignalLineChart(modelProducer: CartesianChartModelProducer, dataPointsSize: Double,
                    height: Dp = 80.dp) {
    CartesianChartHost(
        rememberCartesianChart(
            rememberLineCartesianLayer(
                axisValueOverrider = fullyAdaptiveYValues(),
                lineProvider = LineCartesianLayer.LineProvider.series(
                    rememberLine(
                        shader = DynamicShader.color(BudzColor.green),
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
        modifier = Modifier.height(height).background(Color.Transparent)
    )
}