import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/erp_audio_protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class StopWatch extends StatefulWidget {
  @override
  _StopwatchState createState() => _StopwatchState();
}

class _StopwatchState extends State<StopWatch> with SingleTickerProviderStateMixin {
  Duration _elapsed = Duration.zero;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = this.createTicker((elapsed) {
      setState(() {
        _elapsed = elapsed;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_elapsed.inMilliseconds.toString());
  }
}

class ERPAudioProtocolScreen extends ProtocolScreen {
  static const String id = 'erp_audio_protocol_screen';

  ERPAudioProtocolScreen(RunnableProtocol runnableProtocol) : super(runnableProtocol);

  @override
  Widget runningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    final viewModel = context.watch<ERPAudioProtocolScreenViewModel>();
    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: true,
        backButtonCallback: () async => {
              if (await onBackButtonPressed(context, viewModel)) {Navigator.of(context).pop()}
            },
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LightHeaderText(text: protocol.description + ' EEG Recording'),
              Spacer(),
              Stack(children: [
                Center(
                  child: new Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NextSenseColors.purple,
                    ),
                    child: new Material(
                      child: new InkWell(
                        onTap: () {
                          viewModel.recordButtonPress();
                        },
                        child: new Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle
                          ),
                        ),
                      ),
                      color: Colors.transparent,
                    ),
                  ),
                ),
                if (!viewModel.deviceCanRecord) deviceInactiveOverlay(context, viewModel),
              ]),
              Spacer(),
            ]));
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class
    // type without looking at ancestry.
    return ViewModelBuilder<ERPAudioProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => ERPAudioProtocolScreenViewModel(runnableProtocol),
        onModelReady: (protocolViewModel) => protocolViewModel.init(),
        builder: (context, viewModel, child) => ViewModelBuilder<ProtocolScreenViewModel>.reactive(
            viewModelBuilder: () => viewModel,
            onModelReady: (viewModel) => {},
            builder: (context, viewModel, child) => WillPopScope(
                  onWillPop: () => onBackButtonPressed(context, viewModel),
                  child: body(context, viewModel),
                )));
  }
}