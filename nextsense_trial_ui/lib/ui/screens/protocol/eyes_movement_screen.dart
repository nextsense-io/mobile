import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eyes_movement_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class EyesMovementProtocolScreen extends ProtocolScreen {

  static const String id = 'eyes_movement_protocol_screen';

  EyesMovementProtocolScreen(RunnableProtocol runnableProtocol) :
        super(runnableProtocol);

  @override
  Widget runningStateBody(
      BuildContext context, ProtocolScreenViewModel viewModel) {
    final viewModel = context.watch<EyesMovementProtocolScreenViewModel>();
    final whiteTextStyle = TextStyle(color: Colors.white, fontSize: 20);
    final bigWhiteTextStyle = TextStyle(color: Colors.white, fontSize: 36);
    ProtocolPart currentPart = viewModel.getCurrentProtocolPart()!;

    return Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(color: Colors.black),
        child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(protocol.description, style: whiteTextStyle),
                  Text(viewModel.getTextForProtocolPart(currentPart.state),
                      style: bigWhiteTextStyle),
                  SessionControlButton(runnableProtocol)
                ]
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class
    // type without looking at ancestry.
    return ViewModelBuilder<EyesMovementProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => EyesMovementProtocolScreenViewModel(runnableProtocol),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) =>
        ViewModelBuilder<ProtocolScreenViewModel>.reactive(
            viewModelBuilder: () => viewModel,
            onModelReady: (viewModel) => viewModel.init(),
            builder: (context, viewModel, child) => WillPopScope(
              onWillPop: () => onBackButtonPressed(context, viewModel),
              child: body(context, viewModel),
            )));
  }
}