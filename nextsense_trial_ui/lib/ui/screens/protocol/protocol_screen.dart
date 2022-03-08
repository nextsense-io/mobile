import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/utils/duration.dart';
import 'package:provider/provider.dart';

class ProtocolScreen extends HookWidget {
  Protocol protocol;

  ProtocolScreen(this.protocol);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProtocolScreenViewModel>();

    var timerVisible = useState<bool>(true);

    final whiteTextStyle =  TextStyle(color: Colors.white, fontSize: 20);

    var sessionControlButtonColor = Colors.blue;
    if (viewModel.sessionIsActive) {
      sessionControlButtonColor = Colors.red;
      if (viewModel.protocolCompleted)
        sessionControlButtonColor = Colors.green;
    }

    return WillPopScope(
      onWillPop: ()=>_onBackButtonPressed(context, viewModel),
      child: Scaffold(
          body: Container(
        decoration: BoxDecoration(color: Colors.black),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                protocol.getName(),
                style: whiteTextStyle,
              ),
              SizedBox(
                height: 30,
              ),
              Text(protocol.getDescription(),
                  style: whiteTextStyle),
              SizedBox(
                height: 30,
              ),
              Opacity(
                opacity: 0.3,
                child: Column(
                  children: [
                    Text(
                      "Min duration: " + humanizeDuration(protocol.getMinDuration()),
                      style: whiteTextStyle,
                    ),
                    Text(
                      "Max duration: " + humanizeDuration(protocol.getMaxDuration()),
                      style: whiteTextStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              if (timerVisible.value) _timer(context),
              SizedBox(
                height: 30,
              ),
              Container(
                height: 100,
                child: Visibility(
                  visible: viewModel.sessionIsActive,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                      Text("Test in progress", style: TextStyle(color: Colors.white),)
                    ],
                  ),
                ),
              ),
              Container(
                height: 80,
                child: Visibility(
                  visible: viewModel.protocolCompleted,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Protocol completed!"
                        "\nYou can go ahead until you reach max duration.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green, fontSize: 18)),
                  )
                )
              ),
              SizedBox(
                height: 30,
              ),
              ElevatedButton(
                  style: ButtonStyle(backgroundColor:
                    MaterialStateProperty.all<Color>(sessionControlButtonColor)
                  ),
                  onPressed: () async {
                    if (viewModel.sessionIsActive) {
                      bool confirm = await _confirmStopSessionDialog(context);
                      if (confirm)
                        viewModel.stopSession();
                    }
                    else
                      viewModel.startSession();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      viewModel.sessionIsActive
                          ? "Stop session" : "Start session",
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
    var timerValue = "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
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

  /*
    Once this is pressed, display a timer that shows how long was recorded
    and the maximum time before the protocol finish by itself.

    Have a button to stop the session with a confirmation popup.

     The text in the popup should be different if the time is under
      the minimum recording time.
      Exact text will be provided later, placeholder is fine, just ask to
      confirm and mention that the protocol is not finished, for example.

    Using the Android “back” button should also trigger this popup,
     same as if pressing the stop button.
   */

  Future<bool> _onBackButtonPressed(BuildContext context, ProtocolScreenViewModel viewModel) async {
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
            content: Text('Protocol is not finished yet. Are you sure you want to stop?'),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    //_dismissDialog();
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

}
