import 'package:flutter/material.dart';
import 'package:nextsense_consumer_ui/ui/screens/startup/startup_screen_vm.dart';
import 'package:receive_intent/receive_intent.dart' as intent;
import 'package:stacked/stacked.dart';

class StartupScreen extends StatefulWidget {
  static const String id = 'startup_screen';

  final intent.Intent? initialIntent;

  const StartupScreen({super.key, this.initialIntent});

  @override
  _StartupScreenState createState() => _StartupScreenState(initialIntent: initialIntent);
}

class _StartupScreenState extends State<StartupScreen> {

  final intent.Intent? initialIntent;

  _StartupScreenState({this.initialIntent});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StartupScreenViewModel>.reactive(
        viewModelBuilder: () => StartupScreenViewModel(initialIntent: initialIntent),
        onViewModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return WillPopScope(
            onWillPop: () => _onBackButtonPressed(context, viewModel),
            child: SafeArea(
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        // TODO(alex): move color to separate style file
                        color: Color(0xFF984df1)
                        //color: Colors.lightBlue
                      )
                    ),
                    Column(
                      children: [
                        Expanded(child: Container()),
                        SizedBox(height: 30),
                        _logo(),
                        Expanded(child: Center(
                        child: viewModel.isBusy
                            ? _loadingIndicator()
                            : Container())),
                      ],
                    ),
                  ],
                )),
          );
        }
    );

  }

  Widget _logo() {
    // TODO(alex): match splash screen position?
    return SizedBox(
        width: 155,
        child: Image.asset("packages/nextsense_trial_ui/assets/images/splash_logo.png")
    );
  }

  Widget _loadingIndicator() {
    return const SizedBox(
        height: 40,
        width: 40,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 4.0,
        ));
  }

  Future<bool> _onBackButtonPressed(
      BuildContext context, StartupScreenViewModel viewModel) async {
    Navigator.pop(context, false);
    return true;
  }
}