import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/big_text.dart';
import 'package:flutter_common/ui/components/error_overlay.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

Future<bool?> _confirmStopSessionDialog(BuildContext context,
    ProtocolScreenViewModel viewModel) async {
  String confirmStopText = 'Protocol is not finished yet.\n'
      'Are you sure you want to stop?';
  if (viewModel.minDurationPassed) {
    confirmStopText = 'Are you sure you want to stop?';
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
              onPressed: () async => {
                Navigator.pop(context, true)
              },
              child: Text('Stop'),
            )
          ],
        );
      });
}

class SessionControlButton extends StatelessWidget {

  final String text;
  final Future<bool> Function(BuildContext, ProtocolScreenViewModel) stopSession;

  SessionControlButton(this.stopSession, {this.text = 'Stop'});

  @override
  Widget build(BuildContext context) {
    ProtocolScreenViewModel viewModel = context.watch<ProtocolScreenViewModel>();
    return SimpleButton(
      text: Center(child: MediumText(text: text, color: NextSenseColors.purple, marginLeft: 40,
        marginRight: 40)),
      border: Border.all(width: 2, color: NextSenseColors.purple),
      onTap: () async {
        if (viewModel.sessionIsActive) {
          await stopSession.call(context, viewModel);
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
  final Navigation _navigation = getIt<Navigation>();
  final Logger _logger = Logger('ProtocolScreen');

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

  String getRecordingCancelledMessage(ProtocolScreenViewModel viewModel) {
    switch (viewModel.protocolCancelReason) {
      case ProtocolCancelReason.deviceNotConnected:
        return ' Recording was not started because the device is not connected.\n\n'
            'Please connect and try again';
      case ProtocolCancelReason.deviceNotReadyToRecord:
        return ' Recording was not started because the device is still finishing the previous'
            ' recording.\n\n'
            'Please wait a few seconds and try again.';
      case ProtocolCancelReason.deviceDisconnectedTimeout:
        return ' Recording stopped because the device was unavailable for too long.';
      case ProtocolCancelReason.dataReceivedTimeout:
        return ' Recording stopped because the device failed to start recording.\n\n'
            'Please make sure that the device is fully charged, the earbuds are well-connected, the'
            ' device storage is not full, power it off and on again and try again. If it still did'
            ' not work, please contact support.';
      case ProtocolCancelReason.storageFull:
        return ' Recording stopped because the device storage is full.\n\n'
            'Please make sure that the device storage is not full, power it off and on again and'
            ' try again. If it still did not work, please contact support.';
      case ProtocolCancelReason.devicePoweredOff:
        return ' Recording stopped because the device was powered off.';
      case ProtocolCancelReason.none:
        return '';
    }
  }

  Widget waitingToStartBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    var statusMsg = '';

    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: false,
        backButtonCallback: () async => {
          // Don't allow back at this time as it can put the Xenon device in a bad state to
          // start/stop too fast.
        },
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 20),
              LightHeaderText(text: viewModel.protocol.nameForUser + statusMsg,
                  textAlign: TextAlign.center),
              Spacer(),
              WaitWidget(message: "Please wait while the device gets ready to record"),
              Spacer()
            ]));
  }

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
              // if (isError)
              //   SimpleButton(
              //     text: Center(child: MediumText(text: 'Restart',
              //         color: NextSenseColors.purple)),
              //     border: Border.all(width: 2, color: NextSenseColors.purple),
              //     onTap: () async {
              //       viewModel.startSession();
              //     }),
              // if (isError) SizedBox(height: 10),
              Stack(
                  children: [
                    Center(child: CountDownTimer(duration: protocol.maxDuration, reverse: false,
                        secondsElapsed: (viewModel.milliSecondsElapsed / 1000).round())),
                    if (!viewModel.deviceCanRecord)
                      deviceInactiveOverlay(context, viewModel),
                  ]),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SessionControlButton(stopSession, text: 'Stop'),
                ],
              )
            ]));
  }

  Widget notRunningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    var statusMsg = '';
    if (viewModel.isError) {
      statusMsg = getRecordingCancelledMessage(viewModel);
    } else if (viewModel.protocolCompleted) {
      statusMsg = ' Recording Completed';
    } else {
      statusMsg = ' Recording Cancelled';
    }

    String finishButtonText = 'Go to Tasks';

    if (!viewModel.isError) {
      if (viewModel.postRecordingSurvey != null) {
        finishButtonText = 'Fill Survey';
      }
      if (viewModel.postRecordingProtocol != null) {
        finishButtonText = 'Next Protocol';
      }
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 20),
              LightHeaderText(text: viewModel.protocol.nameForUser + statusMsg,
                  textAlign: TextAlign.center),
              Spacer(),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Spacer(),
                SimpleButton(
                    text: Center(child: MediumText(text: finishButtonText,
                        color: NextSenseColors.purple)),
                    border: Border.all(width: 2, color: NextSenseColors.purple),
                    onTap: () async {
                      navigateOut(context, viewModel);
                    })
              ],)
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
    Widget body;
    if (viewModel.sessionIsActive) {
      if (viewModel.dataReceived) {
        body = runningStateBody(context, viewModel);
      } else {
        body = waitingToStartBody(context, viewModel);
      }
    } else {
      body = notRunningStateBody(context, viewModel);
    }
    return SafeArea(
      child: Scaffold(body: body),
    );
  }

  Future<bool> onBackButtonPressed(
      BuildContext context, ProtocolScreenViewModel viewModel) async {
    if (viewModel.sessionIsActive) {
      if (viewModel.dataReceived) {
        return await stopSession(context, viewModel);
      } else {
        // Don't want to allow back if we are waiting for the device to start recording. It would
        // not stop and keep sending packets to the phone.
        return false;
      }
    }
    return true;
  }

  Future navigateOut(BuildContext context, ProtocolScreenViewModel viewModel) async {
    if (viewModel.protocolCompleted) {
      if (viewModel.postRecordingSurvey != null) {
        await _navigation.navigateTo(SurveyScreen.id, arguments: viewModel.postRecordingSurvey);
      }
      if (viewModel.postRecordingProtocol != null) {
        await _navigation.navigateTo(ProtocolScreen.id, arguments: viewModel.postRecordingProtocol);
      }
    }
    Navigator.of(context).pop();
  }

  Future<bool> stopSession(BuildContext context, ProtocolScreenViewModel viewModel) async {
    bool? confirm = await _confirmStopSessionDialog(context, viewModel);
    if (confirm != null && confirm) {
      await viewModel.stopSession();
    }
    return confirm ?? false;
  }

  Widget deviceInactiveOverlay(BuildContext context, ProtocolScreenViewModel viewModel) {
    final int hours = viewModel.disconnectTimeoutSecondsLeft ~/ 3600;
    final int minutes = (viewModel.disconnectTimeoutSecondsLeft % 3600) ~/ 60;
    final int seconds = viewModel.disconnectTimeoutSecondsLeft % 60;
    String timerValue = "";
    if (hours > 0) {
      timerValue += "${hours.toString().padLeft(2, "0")}:";
    }
    timerValue += "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
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

    return ErrorOverlay(
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
      );
  }
}

class CountDownTimer extends StatelessWidget {
  final Duration duration;
  final bool reverse;
  final int? secondsElapsed;

  CountDownTimer({required this.duration, required this.reverse, this.secondsElapsed});

  @override
  Widget build(BuildContext context) {
    ProtocolScreenViewModel viewModel = context.watch<ProtocolScreenViewModel>();
    return Padding(padding: EdgeInsets.only(top: 5), child: CircularCountDownTimer(
      duration: duration.inSeconds,
      initialDuration: secondsElapsed ?? 0,
      controller: viewModel.countDownController,
      width: MediaQuery.of(context).size.width / 2.5,
      height: MediaQuery.of(context).size.width / 2.5,
      ringColor: reverse ? NextSenseColors.transparent : NextSenseColors.purple,
      fillColor: NextSenseColors.purple,
      backgroundColor: Colors.transparent,
      strokeWidth: 4.0,
      strokeCap: StrokeCap.round,
      textStyle:
          TextStyle(fontSize: 28.0, color: NextSenseColors.purple, fontWeight: FontWeight.w500),
      textFormat: duration.inMinutes >= 60 ? CountdownTextFormat.HH_MM_SS :
          CountdownTextFormat.MM_SS,
      isReverse: reverse,
      isReverseAnimation: reverse,
      isTimerTextShown: true,
      autoStart: true,
    ));
  }
}
