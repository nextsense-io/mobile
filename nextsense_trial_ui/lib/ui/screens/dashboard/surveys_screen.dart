import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/task.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_schedule_view.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:stacked/stacked.dart';

class SurveysScreen extends HookWidget {
  static const String id = 'surveys_screen';

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DashboardScreenViewModel>.reactive(
        viewModelBuilder: () => DashboardScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, DashboardScreenViewModel viewModel, child) =>
            DashboardScheduleView(scheduleType: "Surveys", taskType: TaskType.survey));
  }
}