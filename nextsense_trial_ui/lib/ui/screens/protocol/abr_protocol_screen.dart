import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/abr_protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:stacked/stacked.dart';

class ABRProtocolScreen extends ProtocolScreen {

  static const String id = 'abr_protocol_screen';

  ABRProtocolScreen(RunnableProtocol runnableProtocol) :
        super(runnableProtocol);

  Widget runningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    // The basic body will show a timer while running.
    bool isError = !viewModel.protocolCompleted &&
        viewModel.protocolCancelReason != ProtocolCancelReason.none;
    String statusMsg = ' Recording';
    if (isError) {
      statusMsg = getRecordingCancelledMessage(viewModel);
    }

    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: true,
        backButtonCallback: () async => {
          if (await onBackButtonPressed(context, viewModel)) {
            Navigator.of(context).pop()
          }
        },
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child:
              LightHeaderText(text: protocol.nameForUser + statusMsg,
                  textAlign: TextAlign.center)),
              Spacer(),
              Stack(
                  children: [
                    Center(child: CountDownTimer(duration: protocol.maxDuration, reverse: true,
                        secondsElapsed: (viewModel.milliSecondsElapsed / 1000).round())),
                    if (!viewModel.deviceCanRecord)
                      deviceInactiveOverlay(context, viewModel),
                    if (viewModel.isPausedByUser)
                      protocolPausedByUserOverlay(context, viewModel),
                  ]),
              Spacer(),
              if (viewModel.isResearcher)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SignalMonitoringButton(),
                  ],
                ),
              if (viewModel.isResearcher)
                SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SessionControlButton(stopSession, text: 'Stop'),
                ],
              )
            ]));
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class
    // type without looking at ancestry.
    return ViewModelBuilder<ABRProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => ABRProtocolScreenViewModel(runnableProtocol),
        onViewModelReady: (protocolViewModel) => protocolViewModel.init(),
        builder: (context, viewModel, child) => ViewModelBuilder<ProtocolScreenViewModel>
            .reactive(
            viewModelBuilder: () => viewModel,
            onViewModelReady: (viewModel) => {},
            builder: (context, viewModel, child) => WillPopScope(
              onWillPop: () => onBackButtonPressed(context, viewModel),
              child: body(context, viewModel),
            )));
  }
}