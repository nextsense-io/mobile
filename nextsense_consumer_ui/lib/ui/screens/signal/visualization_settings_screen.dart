import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:nextsense_consumer_ui/ui/components/drop_down_menu.dart';
import 'package:nextsense_consumer_ui/ui/components/header_text.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/screens/signal/signal_monitoring_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/signal/visualization_settings_screen_vm.dart';
import 'package:stacked/stacked.dart';

class VisualizationSettingsScreen extends HookWidget {
  static const String id = 'visualization_settings_screen';

  const VisualizationSettingsScreen({super.key});

  Widget signalProcessingRadio(VisualizationSettingsScreenViewModel viewModel) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 45,
          child: ListTile(
            title: const MediumText(text: 'Raw'),
            leading: Radio(
                value: SignalProcessing.raw,
                groupValue: viewModel.signalProcessingType,
                onChanged: (SignalProcessing? value) {
                  viewModel.setSignalProcessingType(value);
                }),
          ),
        ),
        Expanded(
          flex: 55,
          child: ListTile(
            title: const MediumText(text: 'Filtered'),
            leading: Radio(
                value: SignalProcessing.filtered,
                groupValue: viewModel.signalProcessingType,
                onChanged: (SignalProcessing? value) {
                  viewModel.setSignalProcessingType(value);
                }),
          ),
        ),
      ],
    );
  }

  Widget buildBody(BuildContext context, VisualizationSettingsScreenViewModel viewModel) {
    // if (_loading) {
    //   return Container(
    //     padding: EdgeInsets.all(16),
    //     child: Text(
    //       "Loading settings...",
    //       style: Theme.of(context)
    //           .textTheme
    //           .bodyText1
    //           .copyWith(fontWeight: FontWeight.w300),
    //       textAlign: TextAlign.left,
    //     ),
    //   );
    // }
    return Container(
        alignment: Alignment.center,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: <Widget>[
            const HeaderText(text: "EEG Signal Processing"),
            signalProcessingRadio(viewModel),
            const MediumText(text: "Bandpass Filter"),
            Row(children: <Widget>[
              Expanded(
                flex: 50,
                child: MediumText(
                    text: "Low cut (${VisualizationSettingsScreenViewModel.defaultLowCutFreqHz}-"
                        "${viewModel.lowCutFrequencyMax}): "),
              ),
              Expanded(
                flex: 50,
                child: SpinBox(
                  min: VisualizationSettingsScreenViewModel.defaultLowCutFreqHzMin,
                  max: viewModel.lowCutFrequencyMax!,
                  value: viewModel.lowCutFrequency!,
                  decimals: 1,
                  onChanged: (value) {
                    if (value >= VisualizationSettingsScreenViewModel.defaultLowCutFreqHzMin &&
                        value <= viewModel.lowCutFrequencyMax!) {
                      viewModel.setLowCutFrequency(value);
                    }
                  },
                ),
              )
            ]),
            Row(children: <Widget>[
              Expanded(
                flex: 50,
                child: MediumText(
                    text: "High cut (${viewModel.highCutFrequencyMin}-"
                        "${VisualizationSettingsScreenViewModel.defaultHighCutFreqHzMax}Hz): "),
              ),
              Expanded(
                flex: 50,
                child: SpinBox(
                  min: viewModel.highCutFrequencyMin!,
                  max: VisualizationSettingsScreenViewModel.defaultHighCutFreqHzMax,
                  value: viewModel.highCutFrequency!,
                  decimals: 1,
                  onChanged: (value) {
                    if (value >= viewModel.highCutFrequencyMin! &&
                        value <= VisualizationSettingsScreenViewModel.defaultHighCutFreqHzMax) {
                      viewModel.setHighCutFrequency(value);
                    }
                  },
                ),
              )
            ]),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: const MediumText(text: "Notch Filter"),
            ),
            DropDownMenu(
              title: "Power line frequency (Hz):",
              value: viewModel.powerLineFrequency,
              possibleValues: VisualizationSettingsScreenViewModel.powerLineFrequencies,
              onChanged: (dynamic value) {
                viewModel.setPowerLineFrequency(value);
              },
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<VisualizationSettingsScreenViewModel>.reactive(
        viewModelBuilder: () => VisualizationSettingsScreenViewModel(),
        onViewModelReady: (viewModel) => viewModel.init(),
        builder: (context, VisualizationSettingsScreenViewModel viewModel, child) => PageScaffold(
            showProfileButton: false,
            child: Container(
              alignment: Alignment.center,
              color: Colors.white,
              child: buildBody(context, viewModel),
            )));
  }
}
