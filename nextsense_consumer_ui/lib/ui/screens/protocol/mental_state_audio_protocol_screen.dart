import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_consumer_ui/managers/mental_state_manager.dart';
import 'package:nextsense_consumer_ui/ui/components/light_header_text.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
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

  List<Widget> bandpowerResults(BuildContext context) {
    final viewModel = context.read<MentalStateAudioProtocolScreenViewModel>();

    List<Widget> results = [];
    for (Band band in viewModel.bandPowers.keys) {
      results.add(LightHeaderText(text: '${band.toString().split('.').last} band:'));
      for (double power in viewModel.bandPowers[band] ?? []) {
        results.add(LightHeaderText(text: power.toStringAsFixed(2)));
      }
      results.add(const LightHeaderText(text: '-----------'));
    }
    final int bandpowersSize = viewModel.bandPowers[Band.alpha]?.length ?? 0;
    for (int i = 0; i < bandpowersSize; i++) {
      results.add(LightHeaderText(text:
      'Alpha/Beta ratio ${(viewModel.bandPowers[Band.alpha]![i] /
          viewModel.bandPowers[Band.beta]![i]).toStringAsFixed(2)}'));
      results.add(LightHeaderText(text:
      'Alpha/Theta ratio ${(viewModel.bandPowers[Band.alpha]![i] /
          viewModel.bandPowers[Band.theta]![i]).toStringAsFixed(2)}'));
      results.add(const LightHeaderText(text: '-----------'));
    }
    return results;
  }

  @override
  Widget runningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    final viewModel = context.read<MentalStateAudioProtocolScreenViewModel>();

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
        child: SingleChildScrollView(child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LightHeaderText(text: '${protocol.description} EEG Recording'),
              const SizedBox(height: 10),
              Stack(children: [
                Center(child: CountDownTimer(duration: protocol.maxDuration, reverse: false)),
                if (!viewModel.deviceCanRecord) deviceInactiveOverlay(context, viewModel),
              ]),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(labelText: "Alpha/Beta ratio increase"),
                controller: TextEditingController()..text =
                    viewModel.alphaBetaRatioIncrease.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  double? newValue = double.tryParse(value);
                  if (newValue != null && newValue > 0) {
                    viewModel.alphaBetaRatioIncrease = newValue;
                  }
                },
              ),
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
              LightHeaderText(text: 'Power line frequency:'
                  ' ${viewModel.powerLineFrequency.toStringAsFixed(0)}'),
              const LightHeaderText(text: '-----------'),
              ...bandpowerResults(context),
              const SizedBox(height: 20),
              SessionControlButton(stopSession)
            ])));
  }

  @override
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
        child: SingleChildScrollView(child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              LightHeaderText(text: viewModel.protocol.nameForUser + statusMsg,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ...bandpowerResults(context),
              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Spacer(),
                SimpleButton(
                    text: Center(child: MediumText(text: finishButtonText,
                        color: NextSenseColors.purple)),
                    border: Border.all(width: 2, color: NextSenseColors.purple),
                    onTap: () async {
                      navigateOut(context, viewModel);
                    })
              ],)
            ])));
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