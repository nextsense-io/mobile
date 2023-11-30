import 'package:community_charts_flutter/community_charts_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/text_theme.dart';

import '../../../domain/brain_checking.dart';
import '../../../utils/utils.dart';
import 'brain_checking_vm.dart';

class BrainCheckingResults extends HookWidget {
  final BrainCheckingViewModule viewModel;

  const BrainCheckingResults({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                viewModel.redirectToBrainCheckingTab();
              },
              icon: Image.asset(
                imageBasePath.plus("close_button.png"),
                height: 34,
                width: 34,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Brain Check',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 23),
          Text(
            'RESULTS',
            style: Theme.of(context).textTheme.bodyMediumWithFontWeight600,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                if (index == 0) {
                  // header
                  return Container(
                    width: 353,
                    height: 247,
                    padding: const EdgeInsets.all(20),
                    decoration: ShapeDecoration(
                      color: NextSenseColors.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: prepareChart(viewModel.brainCheckingDataProvider.getData().first),
                  );
                } else if (index ==
                    (viewModel.brainCheckingDataProvider.getReportData().length + 1)) {
                  //Footer
                  return Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        viewModel.redirectToBrainCheckingTab();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: Svg(imageBasePath.plus('btn_start.svg')),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Text(
                          'Done',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  );
                } else {
                  final item = viewModel.brainCheckingDataProvider.getReportData()[index - 1];
                  return _rowReportItem(context, item);
                }
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  thickness: 8,
                  color: Colors.transparent,
                );
              },
              itemCount: viewModel.brainCheckingDataProvider.getReportData().length + 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowReportItem(BuildContext context, BrainCheckingReport checkingReport) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: NextSenseColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkingReport.title,
            style: Theme.of(context).textTheme.bodySmallWithFontWeight600?.copyWith(
                  color: checkingReport.color,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            checkingReport.responseTimeInSecondsInString,
            style: Theme.of(context).textTheme.bodyCaption,
          ),
        ],
      ),
    );
  }

  Widget prepareChart(BrainChecking brainChecking) {
    final slowest = brainChecking.slowest;
    final fastest = brainChecking.fastest;
    final average = brainChecking.average;
    return NumericComboChart(
      feedData(brainChecking),
      animate: true,
      primaryMeasureAxis: NumericAxisSpec(
        tickProviderSpec: BasicNumericTickProviderSpec(
          desiredTickCount: brainChecking.taps.length,
          zeroBound: false,
        ),
        showAxisLine: true,
        tickFormatterSpec: BasicNumericTickFormatterSpec((measure) => '${measure?.toInt()}ms'),
        renderSpec: SmallTickRendererSpec(
          // Tick and Label styling here.
          labelStyle: TextStyleSpec(
            fontSize: 10,
            fontFamily: 'Montserrat',
            color: ColorUtil.fromDartColor(NextSenseColors.remSleep),
          ),
          lineStyle: LineStyleSpec(color: ColorUtil.fromDartColor(NextSenseColors.remSleep)),
        ),
        viewport: NumericExtents(fastest, slowest),
      ),
      domainAxis: NumericAxisSpec(
        showAxisLine: true,
        tickProviderSpec: BasicNumericTickProviderSpec(
          desiredTickCount: brainChecking.taps.length,
          zeroBound: false,
        ),
        renderSpec: SmallTickRendererSpec(
          // Tick and Label styling here.
          labelStyle: TextStyleSpec(
            fontSize: 10,
            fontFamily: 'Montserrat',
            color: ColorUtil.fromDartColor(NextSenseColors.remSleep),
          ),
          lineStyle: LineStyleSpec(color: ColorUtil.fromDartColor(NextSenseColors.remSleep)),
        ),
        viewport: NumericExtents(1, brainChecking.taps.length),
      ),
      // Configure the default renderer as a line renderer. This will be used
      // for any series that does not define a rendererIdKey.
      defaultRenderer: LineRendererConfig(),
      // Custom renderer configuration for the point series.
      customSeriesRenderers: [
        PointRendererConfig(
            // ID used to link series to this renderer.
            customRendererId: 'customPoint')
      ],
      behaviors: [
        RangeAnnotation(
          [
            LineAnnotationSegment(
              brainChecking.average,
              RangeAnnotationAxisType.measure,
              endLabel: '${average}ms',
              color: ColorUtil.fromDartColor(NextSenseColors.awakeSleep),
              labelAnchor: AnnotationLabelAnchor.start,
            ),
            LineAnnotationSegment(
              fastest + 20,
              RangeAnnotationAxisType.measure,
              color: ColorUtil.fromDartColor(NextSenseColors.awakeSleep),
              dashPattern: [2, 2],
            ),
            LineAnnotationSegment(
              slowest - 20,
              RangeAnnotationAxisType.measure,
              color: ColorUtil.fromDartColor(NextSenseColors.awakeSleep),
              labelAnchor: AnnotationLabelAnchor.start,
              dashPattern: [2, 2],
            ),
          ],
          defaultLabelStyleSpec: TextStyleSpec(
            fontSize: 12,
            fontFamily: 'Montserrat',
            color: ColorUtil.fromDartColor(NextSenseColors.awakeSleep),
          ),
        )
      ],
    );
  }

  List<Series<TapData, int>> feedData(BrainChecking brainChecking) {
    int counter = 0;
    final tapsData = brainChecking.taps.map((e) => TapData(counter++, e.getSpendTime())).toList();
    final slowestIndex = tapsData.indexWhere((element) => element.primary == brainChecking.slowest);
    final fastestIndex = tapsData.indexWhere((element) => element.primary == brainChecking.fastest);
    return [
      Series<TapData, int>(
        id: 'Taps',
        colorFn: (_, __) => ColorUtil.fromDartColor(NextSenseColors.awakeSleep),
        domainFn: (TapData tap, _) => tap.domain,
        measureFn: (TapData tap, _) => tap.primary,
        data: tapsData,
      ),
      Series<TapData, int>(
        id: 'MinMaxPoints',
        colorFn: (tap, __) {
          if (tap.domain == slowestIndex) {
            return ColorUtil.fromDartColor(NextSenseColors.coreSleep);
          } else if (tap.domain == fastestIndex) {
            return ColorUtil.fromDartColor(NextSenseColors.deepSleep);
          } else {
            return ColorUtil.fromDartColor(Colors.transparent);
          }
        },
        domainFn: (TapData tap, _) => tap.domain,
        measureFn: (TapData tap, _) => tap.primary,
        data: tapsData,
      )
        // Configure our custom point renderer for this series.
        ..setAttribute(rendererIdKey, 'customPoint'),
    ];
  }
}
