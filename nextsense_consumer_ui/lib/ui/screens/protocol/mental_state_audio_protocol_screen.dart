import 'package:flutter/material.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:nextsense_consumer_ui/ui/components/light_header_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/mental_state_audio_protocol_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class MentalStateAudioProtocolScreen extends ProtocolScreen {

  static const String id = 'mental_state_audio_protocol_screen';

  MentalStateAudioProtocolScreen(Protocol protocol, {super.key}) :
        super(protocol);

  @override
  Widget runningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    final viewModel = context.watch<MentalStateAudioProtocolScreenViewModel>();

    return PageScaffold(
        backgroundColor: NextSenseColors.lightGrey,
        showBackground: false,
        showProfileButton: false,
        showBackButton: false,
        showCancelButton: true,
        backButtonCallback: () async =>
        {
          if (await onBackButtonPressed(context, viewModel)) {Navigator.of(context).pop()}
        },
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LightHeaderText(text: '${protocol.description} EEG Recording'),
              const SizedBox(height: 10),
              Stack(children: [
                Center(child: CountDownTimer(duration: protocol.maxDuration, reverse: true)),
                if (!viewModel.deviceCanRecord) deviceInactiveOverlay(context, viewModel),
              ]),
              const SizedBox(height: 20),
              LightHeaderText(text: 'Alpha: ${viewModel.alphaBandPower.toStringAsFixed(2)}'),
              LightHeaderText(text: 'Beta: ${viewModel.betaBandPower.toStringAsFixed(2)}'),
              LightHeaderText(text: 'Theta: ${viewModel.thetaBandPower.toStringAsFixed(2)}'),
              LightHeaderText(text: 'Delta: ${viewModel.deltaBandPower.toStringAsFixed(2)}'),
              LightHeaderText(text: 'Gamma: ${viewModel.gammaBandPower.toStringAsFixed(2)}'),
              LightHeaderText(text:
                  'Alpha/Beta ratio ${(viewModel.alphaBandPower / viewModel.betaBandPower)
                      .toStringAsFixed(2)}'),
              LightHeaderText(text:
              'Alpha/Theta ratio ${(viewModel.alphaBandPower / viewModel.thetaBandPower)
                  .toStringAsFixed(2)}'),
              const Spacer(),
              SessionControlButton(stopSession)
            ]));
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class
    // type without looking at ancestry.
    return ViewModelBuilder<MentalStateAudioProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => MentalStateAudioProtocolScreenViewModel(protocol),
        onViewModelReady: (protocolViewModel) => protocolViewModel.init(),
        builder: (context, viewModel, child) =>
            ViewModelBuilder<ProtocolScreenViewModel>
            .reactive(
            viewModelBuilder: () => viewModel,
            onViewModelReady: (viewModel) => {},
            builder: (context, viewModel, child) => WillPopScope(
              onWillPop: () => onBackButtonPressed(context, viewModel),
              child: body(context, viewModel),
            )));
  }
}