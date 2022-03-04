import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:provider/provider.dart';

class ProtocolScreen extends HookWidget {
  Protocol protocol;

  ProtocolScreen(this.protocol);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ProtocolScreenViewModel>();
    //Study? study = viewModel.getStudy();

    var timerVisible = useState<bool>(true);

    return Scaffold(
        body: Container(
      decoration: BoxDecoration(color: Colors.black),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              protocol.getName(),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              height: 30,
            ),
            Text(protocol.getDescription(),
                style: TextStyle(color: Colors.white)),
            SizedBox(
              height: 30,
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
            SizedBox(
              height: 30,
            ),
            ElevatedButton(
                onPressed: () {
                  if (viewModel.sessionIsActive)
                    viewModel.stopSession();
                  else
                    viewModel.startSession();
                },
                child: Padding(
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
    ));
  }

  Widget _timer(BuildContext context) {
    final viewModel = context.watch<ProtocolScreenViewModel>();
    var minutes = viewModel.secondsLeft ~/ 60;
    var seconds = viewModel.secondsLeft % 60;
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

}
