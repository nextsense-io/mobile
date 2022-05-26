import 'package:flutter/widgets.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:provider/provider.dart';

class DashboardProgressView extends StatelessWidget {
  const DashboardProgressView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardScreenViewModel>();
    return Text("Progress");
  }
}