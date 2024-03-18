import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/lucid_sleep_stages.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_text_button.dart';
import 'package:lucid_reality/ui/components/oval_button.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/components/solid_circle.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/ui/components/wait_widget.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/sleep/day_screen_vm.dart';
import 'package:lucid_reality/ui/screens/sleep/no_sleep_data_screen.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class DayScreen extends HookWidget {
  const DayScreen({super.key});

  Widget _body(BuildContext context, DayScreenViewModel viewModel) {
    final Navigation _navigation = getIt<Navigation>();
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

    if (viewModel.sleepResultType == SleepResultType.noData && viewModel.askToConnectHealthApps) {
      sleepStageCards.add(AppCard(Column(children: [
        Text("You need to connect to your sleep tracking app to see your sleep data."),
        SizedBox(height: 16),
        OvalButton(
            onTap: () {
              _navigation.navigateTo(NoSleepDataScreen.id);
            },
            text: "Connect",
            showBackground: true),
      ])));
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
                                      child: SleepPieChart.withData(viewModel.chartSleepStages))),
                            Align(
                                alignment: Alignment.center,
                                child: Text("${viewModel.sleepStartEndTime}")),
                            // Align(
                            //     alignment: Alignment.topRight,
                            //     child: Text(
                            //         textAlign: TextAlign.right,
                            //         "Time to sleep\n${viewModel.sleepLatency}")),
                          ]))),
                      SizedBox(height: 16)
                    ] +
                    [
                      if (sleepStageCards.isNotEmpty)
                        ...List.generate(
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
                        )
                    ],
              ),
            ),
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
                  Text("Lucid Reality is not authorized to read sleep data from Health Connect."),
                  SizedBox(height: 16),
                  AppTextButton(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundImage: 'btn_authorize.svg',
                    onPressed: () {
                      viewModel.authorizeHealthApp();
                    },
                    text: "Authorize",
                  )
                ]);
              }
            } else {
              body = Column(children: [
                Text("Health Connect app not installed. It needs to be installed for sleep "
                    "tracking applications to sync their data with Lucid Reality."),
                SizedBox(height: 16),
                OvalButton(
                    onTap: () {
                      viewModel.installHealthConnect();
                    },
                    text: "Install",
                    showBackground: true)
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
