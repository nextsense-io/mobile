import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/screens/startup/startup_screen_vm.dart';
import 'package:receive_intent/receive_intent.dart' as intent;
import 'package:stacked/stacked.dart';

import '../../../utils/utils.dart';

class StartupScreen extends StatefulWidget {
  static const String id = 'startup_screen';

  final intent.Intent? initialIntent;

  StartupScreen({this.initialIntent});

  @override
  _StartupScreenState createState() => _StartupScreenState(initialIntent: initialIntent);
}

class _StartupScreenState extends State<StartupScreen> {
  final intent.Intent? initialIntent;

  _StartupScreenState({this.initialIntent});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => StartupScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return WillPopScope(
          onWillPop: () => _onBackButtonPressed(context, viewModel),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: ExactAssetImage(imageBasePath.plus("splash_screen.png")),
                      fit: BoxFit.fill)),
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 0.65 * MediaQuery.of(context).size.height),
                    alignment: Alignment.center,
                    child: Text("LUCID REALITY",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 0.75 * MediaQuery.of(context).size.height),
                    alignment: Alignment.center,
                    child: Text(
                      "Enhancing human potential",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w300),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _onBackButtonPressed(BuildContext context, StartupScreenViewModel viewModel) async {
    Navigator.pop(context, false);
    return true;
  }
}
