import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/screens/startup/startup_screen_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:receive_intent/receive_intent.dart' as intent;
import 'package:stacked/stacked.dart';

import 'package:lucid_reality/utils/utils.dart';

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(
                    flex: 8,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text("LUCID REALITY",
                      style: Theme.of(context).textTheme.titleMediumWithFontWeight500),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    "Enhancing human potential",
                    style: Theme.of(context).textTheme.bodyMediumWithFontWeight300,
                  ),
                  const Spacer(
                    flex: 2,
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
