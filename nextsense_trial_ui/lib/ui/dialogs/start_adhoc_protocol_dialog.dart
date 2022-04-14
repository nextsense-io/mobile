import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:provider/src/provider.dart';

class StartAdhocProtocolDialog extends HookWidget {
  StartAdhocProtocolDialog({Key? key}) : super(key: key);

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {

    final dashboardViewModel = context.read<DashboardScreenViewModel>();

    List<SimpleDialogOption> options = dashboardViewModel.getAdhocProtocols()
        .map((adhocProtocol) =>
        SimpleDialogOption(
          onPressed: () {
            _navigation.navigateWithCapabilityChecking(
                context,
                ProtocolScreen.id, arguments: adhocProtocol);
          },
          child: Container(
              color: Colors.blue,
              padding: EdgeInsets.all(20.0),
              child: Text(adhocProtocol.protocol.nameForUser, style: TextStyle(
                fontSize: 20, color: Colors.white
              ),),
          ),
        )).toList();

    return SimpleDialog(
      title: const Text('Select adhoc protocol to start'),
      children: options,
    );
  }
}
