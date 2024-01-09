import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_circular_progress_indicator.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:lucid_reality/ui/screens/home/home_container.dart';
import 'package:lucid_reality/ui/screens/learn/Insight_learn.dart';
import 'package:lucid_reality/ui/screens/lucid/lucid_screen_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_settings.dart';
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
            'Hello!',
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
        child: AppCard(
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
