import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/domain/protocol/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/protocol_step_card.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/eoec_protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class EOECProtocolScreen extends ProtocolScreen {

  static const String id = 'eoec_protocol_screen';

  EOECProtocolScreen(RunnableProtocol runnableProtocol) :
        super(runnableProtocol);

  @override
  Widget runningStateBody(
      BuildContext context, ProtocolScreenViewModel viewModel) {
    final viewModel = context.watch<EOECProtocolScreenViewModel>();

    List<ScheduledProtocolPart> scheduledProtocolParts = viewModel.getScheduledProtocolParts();
    List<Widget> protocolStepCards = [];
    for (int i = 0; i < viewModel.repetitions; ++i) {
      List<Widget> repetitionStepCards = [];
      for (int j = 0; j < scheduledProtocolParts.length; ++j) {
        repetitionStepCards.add(ProtocolStepCard(
            image: viewModel.getImageForProtocolPart(scheduledProtocolParts[j].protocolPart.state),
            text: viewModel.getTextForProtocolPart(scheduledProtocolParts[j].protocolPart.state),
            currentStep: i * scheduledProtocolParts.length + j == viewModel.protocolIndex));
      }
      protocolStepCards.addAll(repetitionStepCards);
    }

    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: true,
        backButtonCallback: () => onBackButtonPressed(context, viewModel),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
                  LightHeaderText(text: protocol.description + ' EEG Recording'),
                  SizedBox(height: 10),
                  Stack(
                    children: [
                      Center(child: CountDownTimer(duration: protocol.minDuration, reverse: true),),
                      if (!viewModel.deviceCanRecord)
                        deviceInactiveOverlay(context, viewModel),
                    ]),
                  SizedBox(height: 10),
                ] +
                protocolStepCards +
                [
                  Spacer(),
                  SessionControlButton(stopSession)
                ]));
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class
    // type without looking at ancestry.
    return ViewModelBuilder<EOECProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => EOECProtocolScreenViewModel(runnableProtocol),
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