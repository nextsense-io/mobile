import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/sleep/day_screen.dart';
import 'package:lucid_reality/ui/screens/sleep/month_screen.dart';
import 'package:lucid_reality/ui/screens/sleep/sleep_screen_vm.dart';
import 'package:lucid_reality/ui/screens/sleep/week_screen.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class SleepScreen extends HookWidget {
  const SleepScreen({super.key});

  final _pages = const <Widget>[const DayScreen(), const WeekScreen(), const MonthScreen()];

  @override
  Widget build(BuildContext context) {
    final TabController _tabController = useTabController(initialLength: 3, initialIndex: 0);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => SleepScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sleep'),
              backgroundColor: Colors.transparent,
              bottom: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  image: DecorationImage(
                    image: Svg(imageBasePath.plus('tab_active_bg.svg')),
                    fit: BoxFit.contain,
                  ),
                ),
                indicatorPadding: EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.zero,
                indicatorWeight: double.minPositive,
                labelColor: NextSenseColors.white,
                labelStyle: Theme.of(context).textTheme.bodySmall,
                unselectedLabelColor: NextSenseColors.royalBlue,
                unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
                tabs: const <Widget>[
                  Tab(text: 'Day'),
                  Tab(text: 'Week'),
                  Tab(text: 'Month'),
                ],
                onTap: (index) {
                  _tabController.animateTo(index);
                },
              ),
            ),
            body: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    imageBasePath.plus("app_background.png"),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: _pages,
              ),
            ),
          ),
        );
      },
    );
  }
}
