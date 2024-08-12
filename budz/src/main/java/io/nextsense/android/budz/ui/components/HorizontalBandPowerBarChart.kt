package io.nextsense.android.budz.ui.components

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.viewinterop.AndroidView
import com.github.mikephil.charting.charts.HorizontalBarChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.BarData
import com.github.mikephil.charting.data.BarDataSet
import com.github.mikephil.charting.data.BarEntry
import com.github.mikephil.charting.formatter.ValueFormatter
import kotlin.math.roundToInt

class CategoryBarChartXaxisFormatter(private val values: Array<String>) : ValueFormatter() {

    override fun getFormattedValue(value: Float): String {
        val intValue = value.toInt()
        var label: String = if (intValue >= 0 && intValue < values.size) {
            values[intValue]
        } else {
            ""
        }
        return label
    }
}

private fun getBarDataSet(xData: List<Float>, yData: List<Float>, dataLabels: List<String>) :
        BarDataSet {
    val entries: List<BarEntry> = xData.zip(yData) { x, y -> BarEntry(x, y) }
    val dataSet = BarDataSet(entries, "")
    val xAxisLabels = dataLabels.toTypedArray()
    dataSet.stackLabels = xAxisLabels
    dataSet.color = android.graphics.Color.GREEN
    dataSet.setDrawValues(false)
    return dataSet
}

private fun getYAxisMaxValue(yData: List<Float>, yDataMax: Float?): Float {
    return (yDataMax ?: yData.maxOrNull()?.roundToInt()?.toFloat() ?: 0F)
        .coerceAtLeast(30F)
}

@Composable
fun HorizontalBandPowerBarChart(
    xData: List<Float>,
    yData: List<Float>,
    yDataMax: Float? = null,
    dataLabels: List<String>,
    modifier: Modifier = Modifier
){
    AndroidView(
        modifier = modifier.fillMaxSize(),
        factory = { context ->
            val yDataMaxValue = getYAxisMaxValue(yData, yDataMax)
            val chart = HorizontalBarChart(context)
            val xAxisLabels = dataLabels.toTypedArray()
            chart.data = BarData(getBarDataSet(xData, yData, dataLabels))
            // X Axis is the Right and Left labels for horizontal bar chart.
            chart.xAxis.textSize = 24F
            chart.xAxis.textColor = Color.White.toArgb()
            chart.xAxis.setDrawGridLines(false)
            chart.xAxis.setDrawLabels(true)
            chart.xAxis.isGranularityEnabled = true
            chart.xAxis.granularity = 1F
            chart.xAxis.labelCount = dataLabels.size
            val xAxisFormatter = CategoryBarChartXaxisFormatter(xAxisLabels)
            chart.xAxis.valueFormatter = xAxisFormatter
            chart.xAxis.position = XAxis.XAxisPosition.BOTTOM
            chart.xAxis.xOffset = 10F
            // Axis left is the top axis showing the band power in horizontal bar chart.
            chart.axisLeft.isEnabled = true
            chart.axisLeft.setDrawGridLines(false)
            chart.axisLeft.textSize = 20F
            chart.axisLeft.textColor = Color.White.toArgb()
            chart.axisLeft.axisMinimum = 0F
            chart.axisLeft.axisMaximum = yDataMaxValue
            chart.axisRight.isEnabled = false
            chart.axisRight.setDrawGridLines(false)
            chart.axisRight.setDrawAxisLine(false)
            chart.setDrawBarShadow(false)
            chart.setFitBars(true)
            chart.setPinchZoom(false)
            chart.setScaleEnabled(false)
            chart.setDrawGridBackground(false)
            chart.legend.isEnabled = false
            chart.description.isEnabled = false

            // Refresh and return the chart
            chart.invalidate()
            chart
        },
        update = { chartView ->
            val yDataMaxValue = getYAxisMaxValue(yData, yDataMax)
            chartView.data = BarData(getBarDataSet(xData, yData, dataLabels))
            chartView.axisLeft.axisMaximum = yDataMaxValue
            chartView.notifyDataSetChanged();
            chartView.invalidate();
        }
    )
}