import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/domain/survey/protocol_survey.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/big_text.dart';
import 'package:nextsense_trial_ui/ui/components/error_overlay.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

Future<bool> _confirmStopSessionDialog(BuildContext context,
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
      text: Center(child: MediumText(text: text, color: NextSenseColors.purple)),
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
  final CustomLogPrinter _logger = CustomLogPrinter('ProtocolScreen');

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

  Widget runningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    // The basic body will show a timer while running.
    bool isError = !viewModel.protocolCompleted &&
        viewModel.protocolCancelReason != ProtocolCancelReason.none;
    var statusMsg = ' Recording';
    if (isError) {
      statusMsg = ' EEG Recording stopped because the device was unavailable for too long';
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
                        secondsElapsed: viewModel.secondsElapsed)),
                    if (!viewModel.deviceCanRecord)
                      deviceInactiveOverlay(context, viewModel),
                  ]),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SessionControlButton(stopSession, text: 'Log recording'),
                ],
              )
            ]));
  }

  Widget notRunningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    var statusMsg = '';
    if (viewModel.isError) {
      statusMsg = ' Recording Canceled because the device was unavailable for too long';
    } else if (viewModel.protocolCompleted) {
      statusMsg = ' Recording Completed';
    } else {
      statusMsg = ' Recording Cancelled';
    }

    String finishButtonText = !viewModel.isError && viewModel.postRecordingSurveys.isNotEmpty
        ? 'Fill Survey' : 'Go to Tasks';

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
      return await stopSession(context, viewModel);
    }
    return true;
  }

  Future navigateOut(BuildContext context, ProtocolScreenViewModel viewModel) async {
    if (viewModel.protocolCompleted && viewModel.postRecordingSurveys.isNotEmpty) {
      for (ProtocolSurvey survey in viewModel.postRecordingSurveys) {
        await _navigation.navigateTo(SurveyScreen.id, arguments: survey);
      }
    }
    Navigator.of(context).pop();
  }

  Future<bool> stopSession(BuildContext context, ProtocolScreenViewModel viewModel) async {
    bool confirm = await _confirmStopSessionDialog(context, viewModel);
    if (confirm) {
      await viewModel.stopSession();
    }
    return confirm;
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
