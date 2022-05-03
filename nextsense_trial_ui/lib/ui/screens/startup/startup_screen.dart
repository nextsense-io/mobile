import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/screens/startup/startup_screen_vm.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:stacked/stacked.dart';

class StartupScreen extends StatefulWidget {
  static const String id = 'startup_screen';

  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {

  final CustomLogPrinter _logger = CustomLogPrinter('LoadingScreen');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/background.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StartupScreenViewModel>.reactive(
        viewModelBuilder: () => StartupScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return WillPopScope(
            onWillPop: () => _onBackButtonPressed(context, viewModel),
            child: SafeArea(
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
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
    return Container(
        width: 155,
        child: Image.asset("assets/images/splash_logo.png")
    );
  }

  Widget _loadingIndicator() {
    return SizedBox(
        height: 40,
        width: 40,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 4.0,
        ));
  }

  _onBackButtonPressed(BuildContext context, StartupScreenViewModel viewModel) {
    Navigator.pop(context, false);
  }

}