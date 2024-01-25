import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/components/wait_widget.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/sleep/month_screen_vm.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:stacked/stacked.dart';

class MonthScreen extends HookWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => MonthScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        Widget body;
        if (viewModel.initialised) {
          body = _body(context, viewModel);
        } else {
          body = WaitWidget(message: 'Loading sleep data...');
        }
        return SafeArea(
          child: Scaffold(
            body: AppBody(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, MonthScreenViewModel viewModel) {
    List<AppCard> sleepAverageCards = [];
    for (LucidSleepStage lucidSleepStage in chartedStages) {
      Duration? sleepStageDuration = viewModel.sleepStageAverages[lucidSleepStage];
      if (sleepStageDuration == null) {
        continue;
      }
      sleepAverageCards.add(AppCard(Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text("Average ${lucidSleepStage.getLabel()} sleep",
                    style: Theme.of(context).textTheme.bodySmall)),
            SizedBox(height: 16),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(viewModel.formatSleepDuration(sleepStageDuration),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(color: lucidSleepStage.getColor()))),
          ])));
    }
    List<Row> sleepAverageRows = [];
    int cardIndex = 0;
    Row currentRow = Row(children: []);
    for (AppCard appCard in sleepAverageCards) {
      if (cardIndex != 0 && cardIndex % 2 == 0) {
        sleepAverageRows.add(currentRow);
        currentRow = Row(children: []);
      }
      currentRow.children.add(
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 8, right: cardIndex % 2 == 0 ? 8 : 0),
            child: Flexible(child: appCard),
          ),
        ),
      );
      cardIndex++;
    }
    sleepAverageRows.add(currentRow);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            AppCard(
                              CalendarCarousel(
                                height: 341,
                                maxSelectedDate: DateTime.now().getEndOfMonth(),
                                customDayBuilder: (
                                  isSelectable,
                                  index,
                                  isSelectedDay,
                                  isToday,
                                  isPrevMonthDay,
                                  textStyle,
                                  isNextMonthDay,
                                  isThisMonthDay,
                                  day,
                                ) {
                                  if (viewModel.chartSleepStages.containsKey(day)) {
                                    var sleepStages = viewModel.chartSleepStages[day];
                                    var chartSleepStages = sleepStages
                                        ?.where((element) =>
                                            element.stage
                                                .compareTo(LucidSleepStage.sleeping.getLabel()) !=
                                            0)
                                        .toList();
                                    return ConstrainedBox(
                                      constraints: BoxConstraints.expand(),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SleepPieChart.withDataAndChartConfig(
                                            data: chartSleepStages ?? [],
                                            arcWidth: 4,
                                            margin: 0,
                                          ),
                                          Text('${day.day}', style: textStyle),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return null;
                                  }
                                },
                                onCalendarChanged: (dateTime) {
                                  viewModel.onCalendarChanged.value = dateTime;
                                },
                                rightButtonIcon:
                                    DateTime.now().isSameMonth(viewModel.onCalendarChanged.value)
                                        ? SizedBox.shrink()
                                        : null,
                                iconColor: NextSenseColors.white,
                                headerTextStyle: Theme.of(context).textTheme.bodyMedium,
                                customGridViewPhysics: NeverScrollableScrollPhysics(),
                                daysTextStyle: Theme.of(context).textTheme.bodySmall,
                                weekdayTextStyle:
                                    Theme.of(context).textTheme.bodySmallWithFontWeight600,
                                weekendTextStyle: Theme.of(context).textTheme.bodySmall,
                                prevDaysTextStyle:
                                    Theme.of(context).textTheme.bodySmallWithTextColorRoyalBlue,
                                nextDaysTextStyle:
                                    Theme.of(context).textTheme.bodySmallWithTextColorRoyalBlue,
                                todayBorderColor: Colors.transparent,
                                todayButtonColor: Colors.transparent,
                              ),
                            ),
                            SizedBox(height: 8),
                          ] +
                          sleepAverageRows +
                          [
                            Row(children: [
                              Expanded(
                                child: Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: AppCard(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Sleep duration",
                                                  textAlign: TextAlign.left,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          color:
                                                              LucidSleepStage.sleeping.getColor(),
                                                          fontWeight: FontWeight.bold))),
                                          SizedBox(height: 8),
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Your average sleep this month.",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(color: Colors.white))),
                                          SizedBox(height: 16),
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(viewModel.averageSleepTime?.hhmm ?? "N/A",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                          color:
                                                              LucidSleepStage.sleeping.getColor(),
                                                          fontWeight: FontWeight.bold))),
                                        ]))),
                              )
                            ]),
                            Row(children: [
                              Expanded(
                                child: Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: AppCard(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Time to sleep",
                                                  textAlign: TextAlign.left,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .copyWith(
                                                          color: LucidSleepStage.awake.getColor(),
                                                          fontWeight: FontWeight.bold))),
                                          SizedBox(height: 8),
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Your average time to sleep this month.",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(color: Colors.white))),
                                          SizedBox(height: 16),
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                  viewModel.averageSleepLatency?.hhmm ?? "N/A",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                          color: LucidSleepStage.awake.getColor(),
                                                          fontWeight: FontWeight.bold))),
                                        ]))),
                              )
                            ])
                          ])))
        ]);
  }
}
