import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/components/solid_circle.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/ui/components/wait_widget.dart';
import 'package:lucid_reality/ui/screens/sleep/day_screen_vm.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class DayScreen extends HookWidget {
  const DayScreen({super.key});

  Widget _body(BuildContext context, DayScreenViewModel viewModel) {
    List<AppCard> sleepStageCards = [];
    for (var sleepStage in viewModel.chartSleepStages
        .where((element) => element.stage.compareTo(LucidSleepStage.sleeping.getLabel()) != 0)) {
      sleepStageCards.add(
        AppCard(Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          SolidCircle(color: sleepStage.color, size: 16),
          SizedBox(width: 8),
          Text(sleepStage.stage),
          Spacer(),
          Text(textAlign: TextAlign.right, "${sleepStage.duration.hhmm}"),
        ])),
      );
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppCard(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            SvgButton(
              onPressed: () {
                viewModel.changeDay(-1);
              },
              imageName: 'backward_arrow.svg',
            ),
            Text(
              viewModel.currentDate.date,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (DateTime.now().dateNoTime.isAfter(viewModel.currentDate))
              SvgButton(
                onPressed: () {
                  viewModel.changeDay(1);
                },
                imageName: 'forward_arrow.svg',
              )
            else
              SizedBox(width: 54),
          ])),
          SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          AppCard(Container(
                              height: 250,
                              child: Stack(children: [
                                Align(
                                    alignment: Alignment.topLeft,
                                    child: Text("Total time\n${viewModel.totalSleepTime}")),
                                if (viewModel.sleepResultType != SleepResultType.noData)
                                  Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                          height: 250,
                                          child:
                                              SleepPieChart.withData(viewModel.chartSleepStages))),
                                Align(
                                    alignment: Alignment.center,
                                    child: Text("${viewModel.sleepStartEndTime}")),
                                Align(
                                    alignment: Alignment.topRight,
                                    child: Text(
                                        textAlign: TextAlign.right,
                                        "Time to sleep\n${viewModel.sleepLatency}")),
                              ]))),
                          SizedBox(height: 16)
                        ] +
                        List.generate(
                          sleepStageCards.length * 2 - 1,
                          (index) {
                            if (index.isOdd) {
                              return Divider(
                                height: 8,
                                color: Colors.transparent, // Adjust color as needed
                              );
                            } else {
                              final itemIndex = index ~/ 2;
                              return sleepStageCards[itemIndex];
                            }
                          },
                        ))),
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
        viewModelBuilder: () => DayScreenViewModel(),
        onViewModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          Widget body;
          if (viewModel.initialised) {
            if (viewModel.healthAppInstalled) {
              if (viewModel.healthAppAuthorized) {
                body = _body(context, viewModel);
              } else {
                body = Column(children: [
                  Text("Health app not authorized"),
                  ElevatedButton(
                      onPressed: () {
                        viewModel.authorizeHealthApp();
                      },
                      child: Text("Authorize"))
                ]);
              }
            } else {
              body = Column(children: [
                Text("Health app not installed"),
                ElevatedButton(
                    onPressed: () {
                      viewModel.checkHealthAppInstalled();
                    },
                    child: Text("Check again"))
              ]);
            }
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
