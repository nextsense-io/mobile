import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/sleep_bar_chart.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/ui/components/wait_widget.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/ui/screens/sleep/week_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class WeekScreen extends HookWidget {
  const WeekScreen({super.key});

  Widget _body(BuildContext context, WeekScreenViewModel viewModel) {
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
          Padding(padding: EdgeInsets.only(bottom: 8, right: 8), child: Expanded(child: appCard)));
      cardIndex++;
    }
    sleepAverageRows.add(currentRow);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppCard(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            SvgButton(
              onPressed: () {
                viewModel.changeDay(-7);
              },
              imageName: 'backward_arrow.svg',
            ),
            Text(
              viewModel.weekDateRange,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (DateTime.now().dateNoTime.isAfter(viewModel.currentDate))
              SvgButton(
                onPressed: () {
                  viewModel.changeDay(7);
                },
                imageName: 'forward_arrow.svg',
              )
            else
              SizedBox(width: 54),
          ])),
          SizedBox(height: 8),
          AppCard(SizedBox(height: 150, child: SleepBarChart.withData(viewModel.daySleepStages))),
          SizedBox(height: 8),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sleepAverageRows +
                      [
                        Row(children: [
                          Padding(
                              padding: EdgeInsets.only(bottom: 8, right: 8),
                              child: AppCard(
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Sleep duration",
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                            color: LucidSleepStage.sleeping.getColor(),
                                            fontWeight: FontWeight.bold))),
                                SizedBox(height: 8),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Your average sleep this week.",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(color: Colors.white))),
                                SizedBox(height: 16),
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        viewModel.formatSleepDuration(viewModel.averageSleepTime),
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                            color: LucidSleepStage.sleeping.getColor(),
                                            fontWeight: FontWeight.bold))),
                              ])))
                        ])
                      ]))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
        viewModelBuilder: () => WeekScreenViewModel(),
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
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      imageBasePath.plus("app_background.png"),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: body),
                ),
              ),
            ),
          );
        });
  }
}
