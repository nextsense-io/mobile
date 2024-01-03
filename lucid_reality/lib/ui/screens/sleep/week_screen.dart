import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/ui/components/wait_widget.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/ui/screens/sleep/week_screen_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class WeekScreen extends HookWidget {
  const WeekScreen({super.key});

  Widget _body(BuildContext context, WeekScreenViewModel viewModel) {
    List<AppCard> sleepAverageCards = [];
    for (var sleepStage in viewModel.sleepStageAverages.entries) {
      sleepAverageCards.add(AppCard(Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Text("Average ${sleepStage.key.getLabel()} sleep"),
        SizedBox(width: 8),
        Text(viewModel.formatSleepDuration(sleepStage.value),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(color: sleepStage.key.getColor())),
        Spacer(),
        Text(textAlign: TextAlign.right, "${viewModel.formatSleepDuration(sleepStage.value)}"),
      ])));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AppCard(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            SvgButton(
              onTap: () {
                viewModel.changeDay(-7);
              },
              svgPath: imageBasePath.plus('backward_arrow.svg'),
            ),
            Text(
              viewModel.weekDateRange,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (DateTime.now().dateNoTime.isAfter(viewModel.currentDate))
              SvgButton(
                onTap: () {
                  viewModel.changeDay(7);
                },
                svgPath: imageBasePath.plus('forward_arrow.svg'),
              )
            else
              SizedBox(width: 54),
          ])),
          SizedBox(height: 16),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sleepAverageCards +
                      [
                        AppCard(Column(children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Sleep duration",
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: NextSenseColors.royalPurple,
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
                              child: Text(viewModel.formatSleepDuration(viewModel.averageSleepTime),
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: NextSenseColors.royalPurple,
                                      fontWeight: FontWeight.bold))),
                        ]))
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
                      imageBasePath.plus("onboarding_bg.png"),
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
