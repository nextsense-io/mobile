import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/big_text.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

Future<bool> _confirmStopSessionDialog(BuildContext context,
    ProtocolScreenViewModel viewModel) async {
  String confirmStopText = 'Protocol is not finished yet.\n'
      'Are you sure you want to stop?';
  if (viewModel.minDurationPassed) {
    confirmStopText = 'Protocol minimum time successfully passed!\n'
        'You can continue protocol until maximum duration reached.\n'
        'Do you want to stop?';
  }
  return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Stop session?'),
          content: Text(confirmStopText),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Continue')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Stop'),
            )
          ],
        );
      });
}

class SessionControlButton extends StatelessWidget {

  final RunnableProtocol _runnableProtocol;

  SessionControlButton(RunnableProtocol runnableProtocol) : _runnableProtocol = runnableProtocol;

  @override
  Widget build(BuildContext context) {
    ProtocolScreenViewModel viewModel = context.watch<ProtocolScreenViewModel>();
    return SimpleButton(
      text: Center(child: MediumText(text: 'Stop', color: NextSenseColors.purple)),
      border: Border.all(width: 2, color: NextSenseColors.purple),
      onTap: () async {
        if (viewModel.sessionIsActive) {
          bool confirm = await _confirmStopSessionDialog(context, viewModel);
          if (confirm) {
            viewModel.stopSession();
            // Exit from protocol screen for adhoc
            if (_runnableProtocol.type == RunnableProtocolType.adhoc) {
              Navigator.pop(context);
            }
          }
        } else if (viewModel.deviceIsConnected) {
          viewModel.startSession();
        } else {
          await showDialog(
              context: context,
              builder: (_) => SimpleAlertDialog(
                  title: 'Connection error', content: 'Device is not connected.'));
        }
      },
    );
  }
}

class ProtocolScreen extends HookWidget {

  static const String id = 'protocol_screen';

  final RunnableProtocol runnableProtocol;

  Protocol get protocol => runnableProtocol.protocol;

  ProtocolScreen(this.runnableProtocol);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => ProtocolScreenViewModel(runnableProtocol),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) => WillPopScope(
          onWillPop: () => onBackButtonPressed(context, viewModel),
          child: body(context, viewModel),
        ));
  }

  Widget runningStateBody(
      BuildContext context, ProtocolScreenViewModel viewModel) {
    // The basic body will show a timer while running.
    return notRunningStateBody(context, viewModel);
  }

  Widget notRunningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    bool isError = !viewModel.protocolCompleted &&
        viewModel.protocolCancelReason != ProtocolCancelReason.none;
    var statusMsg = '';
    if (isError) {
      statusMsg = ' EEG Recording Canceled because the device was unavailable for too long';
    } else if (viewModel.protocolCompleted) {
      statusMsg = ' EEG Recording Completed!';
    }

    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: true,
        backButtonCallback: () => onBackButtonPressed(context, viewModel),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Spacer(),
              LightHeaderText(text: protocol.description + statusMsg,
                  textAlign: TextAlign.center),
              Spacer(),
              // if (isError)
              //   SimpleButton(
              //     text: Center(child: MediumText(text: 'Restart',
              //         color: NextSenseColors.purple)),
              //     border: Border.all(width: 2, color: NextSenseColors.purple),
              //     onTap: () async {
              //       viewModel.startSession();
              //     }),
              // if (isError) SizedBox(height: 10),
              SimpleButton(
                  text: Center(child: MediumText(text: 'Back to Tasks',
                      color: NextSenseColors.purple)),
                  border: Border.all(width: 2, color: NextSenseColors.purple),
                  onTap: () async {
                    Navigator.pop(context);
                  })
            ]));

    // Re-add status messages.
    // Container(
    //   child: Visibility(
    //     visible: viewModel.hasError,
    //       child: Column(
    //         children: [
    //           Text(viewModel.modelError ?? "",
    //             style: TextStyle(color: Colors.white),
    //            )
    //           ],
    //       ),
    //   ),
    // ),
  }

  Widget body(BuildContext context, ProtocolScreenViewModel viewModel) {
    return SafeArea(
      child: Scaffold(
          body: viewModel.sessionIsActive ?
              runningStateBody(context, viewModel) :
              notRunningStateBody(context, viewModel)),
    );
  }

  Future<bool> onBackButtonPressed(
      BuildContext context, ProtocolScreenViewModel viewModel) async {
    if (viewModel.sessionIsActive) {
      bool confirm = await _confirmStopSessionDialog(context, viewModel);
      if (confirm) {
        viewModel.stopSession();
        return true;
      }
      return false;
    }
    return true;
  }

  Widget deviceInactiveOverlay(BuildContext context, ProtocolScreenViewModel viewModel) {
    final int minutes = viewModel.disconnectTimeoutSecondsLeft ~/ 60;
    final int seconds = viewModel.disconnectTimeoutSecondsLeft % 60;
    String timerValue =
        "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
    String explanationText = 'Device is not connected.';
    String remediationText = 'The protocol will be marked as cancelled if the '
        'connection is not brought back online before:';
    if (!viewModel.isHdmiCablePresent) {
      explanationText = 'The earbuds cable is disconnected.';
      remediationText = 'The protocol will be marked as cancelled if the '
          'earbuds are not reconnected before:';
    } else if (!viewModel.isUSdPresent) {
      explanationText = 'The micro sd card is not inserted in the device.';
      remediationText = 'The protocol will be marked as cancelled if the '
          'micro sd card is not reinserted before:';
    }

    return Opacity(
      opacity: 0.9,
      child: Container(
        height: 260,
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_off,
              color: NextSenseColors.purple,
              size: 60,
            ),
            LightHeaderText(
              text: explanationText,
              textAlign: TextAlign.center,
            ),
            if (viewModel.sessionIsActive) ...[
              SizedBox(height: 30),
              LightHeaderText(text: remediationText, textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              BigText(text: timerValue)
            ]
          ],
        ),
      ),
    );
  }
}

class CountDownTimer extends StatelessWidget {
  final Duration duration;

  CountDownTimer({required this.duration});

  @override
  Widget build(BuildContext context) {
    ProtocolScreenViewModel viewModel = context.watch<ProtocolScreenViewModel>();
    return Padding(padding: EdgeInsets.only(top: 5), child: CircularCountDownTimer(
      duration: duration.inSeconds,
      controller: viewModel.countDownController,
      width: MediaQuery.of(context).size.width / 2.5,
      height: MediaQuery.of(context).size.width / 2.5,
      ringColor: NextSenseColors.transparent,
      fillColor: NextSenseColors.purple,
      backgroundColor: Colors.transparent,
      strokeWidth: 4.0,
      strokeCap: StrokeCap.round,
      textStyle:
          TextStyle(fontSize: 36.0, color: NextSenseColors.purple, fontWeight: FontWeight.w500),
      textFormat: CountdownTextFormat.MM_SS,
      isReverse: true,
      isReverseAnimation: true,
      isTimerTextShown: true,
      autoStart: true,
    ));
  }
}
