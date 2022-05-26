import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';

class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardScreenViewModel>();
    return Text("Home");
  }
}