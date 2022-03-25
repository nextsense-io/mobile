import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/device_state_debug_menu.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/utils/duration.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class ProtocolScreen extends HookWidget {

  static const String id = 'protocol_screen';

  final Protocol protocol;

  ProtocolScreen(this.protocol);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => ProtocolScreenViewModel(protocol),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) => WillPopScope(
          onWillPop: () => _onBackButtonPressed(context, viewModel),
          child: _body(context, viewModel),
        ));
  }

  Widget _body(BuildContext context, ProtocolScreenViewModel viewModel) {
    final whiteTextStyle = TextStyle(color: Colors.white, fontSize: 20);

    var sessionControlButtonColor = Colors.blue;
    if (viewModel.sessionIsActive) {
      sessionControlButtonColor = Colors.red;
      if (viewModel.protocolCompleted) {
        sessionControlButtonColor = Colors.green;
      }
    }
    return SafeArea(
      child: Scaffold(
          body: Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(color: Colors.black),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: DeviceStateDebugMenu())),
                  /*Text(
                protocol.getName(),
                style: whiteTextStyle,
              ),*/
                  Text(protocol.description, style: whiteTextStyle),
                  Opacity(
                    opacity: 0.3,
                    child: Column(
                      children: [
                        Text(
                          "Min duration: " +
                              humanizeDuration(protocol.minDuration),
                          style: whiteTextStyle,
                        ),
                        Text(
                          "Max duration: " +
                              humanizeDuration(protocol.maxDuration),
                          style: whiteTextStyle,
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      Center(child: _timer(context)),
                      if (!viewModel.deviceCanRecord)
                        _deviceInactiveOverlay(context, viewModel)
                    ],
                  ),
                  Container(
                    child: Visibility(
                      visible:
                      viewModel.sessionIsActive && viewModel.deviceIsConnected,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                          Text(
                            "Test in progress",
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                  _statusMessage(viewModel),
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              sessionControlButtonColor)),
                      onPressed: () async {
                        if (viewModel.sessionIsActive) {
                          bool confirm = await _confirmStopSessionDialog(context,
                              viewModel);
                          if (confirm) {
                            viewModel.stopSession();
                          }
                        } else if (viewModel.deviceIsConnected) {
                            viewModel.startSession();
                        } else {
                          await showDialog(
                            context: context,
                            builder: (_) => SimpleAlertDialog(
                                  title: 'Connection error',
                                  content: 'Device is not connected.')
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          viewModel.sessionIsActive
                              ? "Stop session"
                              : "Start session",
                          style: TextStyle(fontSize: 30.0),
                        ),
                      )),
                ],
              ),
            ),
          )),
    );
  }

  Widget _timer(BuildContext context) {
    final viewModel = context.watch<ProtocolScreenViewModel>();
    final int minutes = viewModel.secondsElapsed ~/ 60;
    final int seconds = viewModel.secondsElapsed % 60;
    var timerValue =
        "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
    return Container(
      decoration: new BoxDecoration(
          color: Colors.white,
          borderRadius: new BorderRadius.all(const Radius.circular(100.0))),
      width: 200,
      height: 200,
      child: Center(
        child: Text(
          timerValue,
          style: TextStyle(fontSize: 60.0),
        ),
      ),
    );
  }

  Future<bool> _onBackButtonPressed(
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
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text('Continue')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text('Stop'),
              )
            ],
          );
        });
  }

  Widget _deviceInactiveOverlay(
      BuildContext context, ProtocolScreenViewModel viewModel) {
    final int minutes = viewModel.disconnectTimeoutSecondsLeft ~/ 60;
    final int seconds = viewModel.disconnectTimeoutSecondsLeft % 60;
    String timerValue =
        "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";

    final countdownTimerText =
      Text(timerValue, style: TextStyle(color: Colors.white, fontSize: 20));

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
        height: 200,
        width: double.infinity,
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_off,
              color: Colors.white,
              size: 60,
            ),
            Text(
              explanationText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
            if (viewModel.sessionIsActive) ...[
              SizedBox(
                height: 30,
              ),
              Text(remediationText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(
                height: 10,
              ),
              countdownTimerText
            ]
          ],
        ),
      ),
    );
  }

  Widget _statusMessage(ProtocolScreenViewModel viewModel) {
    bool isError = !viewModel.protocolCompleted &&
        viewModel.protocolCancelReason != ProtocolCancelReason.none;

    var statusMsg = '';

    if (isError) {
      if (viewModel.protocolCancelReason ==
          ProtocolCancelReason.deviceDisconnectedTimeout)
      {
        statusMsg = 'Protocol canceled because \n'
            'device was unavailable for too long';
      }
    }
    else if (viewModel.protocolCompleted) {
      statusMsg = 'Protocol completed!'
          '\nYou can go ahead until you reach max duration.';
      if (viewModel.maxDurationPassed) {
        statusMsg = 'Protocol completed!';
      }
    }

    return Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              statusMsg,
              textAlign: TextAlign.center,
              style:
              TextStyle(color: isError ? Colors.red : Colors.green,
                  fontSize: 18)),
        ));
  }

}
