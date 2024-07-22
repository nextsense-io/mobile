package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.patrykandpatrick.vico.compose.cartesian.CartesianChartHost
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
import com.patrykandpatrick.vico.core.common.shader.DynamicShader
import io.nextsense.android.budz.ui.theme.BudzColor

@Composable
fun SignalLineChart(modelProducer: CartesianChartModelProducer, dataPointsSize: Double) {
//    val axisValueOverrider = AxisValueOverrider.fixed(
//        maxY = 1500.0,
//        minY = -1500.0
//    )
    CartesianChartHost(
        rememberCartesianChart(
            rememberLineCartesianLayer(
//                axisValueOverrider = axisValueOverrider,
                lineProvider = LineCartesianLayer.LineProvider.series(
                    rememberLine(
                        shader = DynamicShader.color(BudzColor.darkBlue),
                        backgroundShader = null
                    )
                ),
            ),
            horizontalLayout = HorizontalLayout.fullWidth(),
            startAxis = null,
            bottomAxis = null,
        ),
        modelProducer,
        zoomState = rememberVicoZoomState(initialZoom = Zoom.x(dataPointsSize),
            zoomEnabled = true),
        scrollState = rememberVicoScrollState(scrollEnabled = false),
        animationSpec = null,
        runInitialAnimation = false,
        modifier = Modifier.height(80.dp).background(Color.Transparent)
    )
}