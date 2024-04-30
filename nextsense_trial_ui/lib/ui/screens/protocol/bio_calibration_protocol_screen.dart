import 'package:flutter/material.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/session/runnable_protocol.dart';
import 'package:nextsense_trial_ui/ui/components/light_header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/protocol_step_card.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/bio_calibration_protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stacked/stacked.dart';

class ProtocolPartScrollView extends StatelessWidget {
  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BioCalibrationProtocolScreenViewModel>();
    List<ProtocolPart> protocolParts = viewModel.getRemainingProtocolParts();

    return ScrollablePositionedList.builder(
      initialScrollIndex: 0,
      itemCount: protocolParts.length,
      itemScrollController: itemScrollController,
      shrinkWrap: true,
      itemBuilder: (context, index) => ProtocolStepCard(
          image: viewModel.getImageForProtocolPart(protocolParts[index].state),
          text: viewModel.getTextForProtocolPart(protocolParts[index].state),
          currentStep: index == 0),
    );
  }
}

class BioCalibrationProtocolScreen extends ProtocolScreen {
  static const String id = 'bio_calibration_protocol_screen';

  BioCalibrationProtocolScreen(RunnableProtocol runnableProtocol) : super(runnableProtocol);

  @override
  Widget runningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    final viewModel = context.watch<BioCalibrationProtocolScreenViewModel>();

    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: true,
        backButtonCallback: () async => {
              if (await onBackButtonPressed(context, viewModel)) {Navigator.of(context).pop()}
            },
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
                  LightHeaderText(text: protocol.description + ' EEG Recording'),
                  SizedBox(height: 10),
                  Stack(children: [
                    Center(child: CountDownTimer(duration: protocol.minDuration, reverse: true)),
                    if (!viewModel.deviceCanRecord) deviceInactiveOverlay(context, viewModel),
                  ]),
                  SizedBox(height: 10),
                  Expanded(child: ProtocolPartScrollView())
                ] +
                [
                  if (viewModel.isResearcher)
                    SizedBox(height: 20),
                  if (viewModel.isResearcher)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SignalMonitoringButton(),
                      ],
                    ),
                  SizedBox(height: 20),
                  SessionControlButton(stopSession)
                ]));
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class
    // type without looking at ancestry.
    return ViewModelBuilder<BioCalibrationProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => BioCalibrationProtocolScreenViewModel(runnableProtocol),
        onModelReady: (protocolViewModel) => protocolViewModel.init(),
        builder: (context, viewModel, child) => ViewModelBuilder<ProtocolScreenViewModel>.reactive(
            viewModelBuilder: () => viewModel,
            onModelReady: (viewModel) => {},
            builder: (context, viewModel, child) => WillPopScope(
                  onWillPop: () => onBackButtonPressed(context, viewModel),
                  child: body(context, viewModel),
                )));
  }
}
