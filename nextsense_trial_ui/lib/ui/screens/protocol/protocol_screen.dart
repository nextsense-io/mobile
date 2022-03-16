import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_debug_menu.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/utils/duration.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class ProtocolScreen extends HookWidget {
  Protocol protocol;

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
      if (viewModel.protocolCompleted) sessionControlButtonColor = Colors.green;
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
                  width: 200,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      color: Colors.grey[800]),
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: ProtocolDebugMenu())),
              /*Text(
                protocol.getName(),
                style: whiteTextStyle,
              ),*/
              Text(protocol.getDescription(), style: whiteTextStyle),
              Opacity(
                opacity: 0.3,
                child: Column(
                  children: [
                    Text(
                      "Min duration: " +
                          humanizeDuration(protocol.getMinDuration()),
                      style: whiteTextStyle,
                    ),
                    Text(
                      "Max duration: " +
                          humanizeDuration(protocol.getMaxDuration()),
                      style: whiteTextStyle,
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  Center(child: _timer(context)),
                  if (!viewModel.deviceIsConnected)
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
                      bool confirm = await _confirmStopSessionDialog(context);
                      if (confirm) viewModel.stopSession();
                    } else
                      if (viewModel.deviceIsConnected)
                        viewModel.startSession();
                      else
                      {
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SimpleAlertDialog(
                                title: 'Connection error',
                                content: 'Device is not connected.');
                          },
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
    var minutes = viewModel.secondsElapsed ~/ 60;
    var seconds = viewModel.secondsElapsed % 60;
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
      bool confirm = await _confirmStopSessionDialog(context);
      if (confirm) {
        viewModel.stopSession();
        return true;
      }
      return false;
    }
    return true;
  }

  Future<bool> _confirmStopSessionDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Stop session?'),
            content: Text(
                'Protocol is not finished yet. Are you sure you want to stop?'),
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
    var minutes = viewModel.disconnectTimeoutSecondsLeft ~/ 60;
    var seconds = viewModel.disconnectTimeoutSecondsLeft % 60;
    var timerValue =
        "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";

    final countdownTimer =
        Text(timerValue, style: TextStyle(color: Colors.white, fontSize: 20));

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
              "Device is not connected!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
            if (viewModel.sessionIsActive) ...[
              SizedBox(
                height: 30,
              ),
              Text(
                'The protocol will be marked as cancelled if the '
                'connection is not brought back online before:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(
                height: 10,
              ),
              countdownTimer
            ]
          ],
        ),
      ),
    );
  }

  Widget _statusMessage(ProtocolScreenViewModel viewModel) {
    var isError = !viewModel.protocolCompleted &&
        viewModel.protocolCancelReason != ProtocolCancelReason.none;

    var statusMsg = "";

    if (isError) {
      if (viewModel.protocolCancelReason ==
          ProtocolCancelReason.deviceDisconnectedTimeout)
        {
          statusMsg = "Protocol canceled because \n"
              "device was disconnected too long";
        }
    }
    else if (viewModel.protocolCompleted) {
      statusMsg = "Protocol completed!"
          "\nYou can go ahead until you reach max duration.";
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
