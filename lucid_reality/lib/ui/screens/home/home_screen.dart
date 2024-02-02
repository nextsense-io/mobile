import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_circular_progress_indicator.dart';
import 'package:lucid_reality/ui/components/app_text_buttton.dart';
import 'package:lucid_reality/ui/components/sleep_pie_chart.dart';
import 'package:lucid_reality/ui/components/wait_widget.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:lucid_reality/ui/screens/home/home_container.dart';
import 'package:lucid_reality/ui/screens/learn/insight_learn.dart';
import 'package:lucid_reality/ui/screens/lucid/lucid_screen_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_settings.dart';
import 'package:lucid_reality/ui/screens/sleep/day_screen_vm.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class HomeScreen extends HookWidget {
  final DashboardScreenViewModel viewModel;

  const HomeScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello ${viewModel.getUserName()},',
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(
            height: 38,
          ),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) => buildHomeItem(context)[index],
              separatorBuilder: (context, index) {
                return const Divider(
                  thickness: 8,
                  color: Colors.transparent,
                );
              },
              itemCount: 4,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildHomeItem(BuildContext context) {
    return [
      HomeContainer(
        title: 'YOUR SLEEP SUMMARY',
        child: ViewModelBuilder.reactive(
          viewModelBuilder: () => DayScreenViewModel(),
          onViewModelReady: (viewModel) => viewModel.init(),
          builder: (context, viewModel, child) {
            if (viewModel.initialised) {
              if (!viewModel.healthAppAuthorized) {
                return Column(children: [
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
              if (viewModel.sleepResultType == SleepResultType.sleepStaging ||
                  viewModel.sleepResultType == SleepResultType.sleepTimeOnly) {
                return AppCard(
                  Container(
                    height: 199,
                    child: Stack(
                      children: [
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
                          child: Text(
                            "${viewModel.sleepStartEndTime}",
                            style: Theme.of(context).textTheme.bodyCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return AppCard(
                  SizedBox(
                    height: 199,
                    width: double.maxFinite,
                    child: Center(
                      child: Text(
                        textAlign: TextAlign.center,
                        'Oops!\nNo Data to generate Sleep Summary',
                        style: Theme.of(context).textTheme.bodyCaption,
                      ),
                    ),
                  ),
                );
              }
            } else {
              return WaitWidget(message: 'Loading sleep data...');
            }
          },
        ),
      ),
      HomeContainer(
        title: 'LEARN',
        child: InsightLearn(
          onItemClick: (insightLearnItem) {
            viewModel.onInsightItemClick(insightLearnItem);
          },
        ),
      ),
      HomeContainer(
        title: 'BRAIN CHECK',
        child: InkWell(
          onTap: () {
            viewModel.navigateToPVTTab();
          },
          child: AppCard(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Test your focus and reaction time',
                    style: Theme.of(context).textTheme.bodySmallWithFontWeight600,
                  ),
                ),
                Image.asset(imageBasePath.plus('home_brain_icon.png'))
              ],
            ),
          ),
        ),
      ),
      HomeContainer(
        title: 'LUCID DREAMING',
        showForwardButton: true,
        onForwardButtonPressed: () {
          this.viewModel.navigateToCategoryScreen();
        },
        child: ViewModelBuilder.reactive(
          viewModelBuilder: () => LucidScreenViewModel(),
          onViewModelReady: (viewModel) => viewModel.init(),
          builder: (context, viewModel, child) {
            return viewModel.isBusy
                ? AppCircleProgressIndicator()
                : RealityCheckSettings(
                    viewModel,
                    viewType: RealitySettingsViewType.home,
                    onSetupSettings: () {
                      this.viewModel.navigateToCategoryScreen();
                    },
                  );
          },
        ),
      ),
    ];
  }
}
