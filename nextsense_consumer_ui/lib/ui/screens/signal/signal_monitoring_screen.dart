import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/acceleration_plot_data.dart';
import 'package:flutter_common/ui/components/eeg_fixed_plot_data.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/ui/components/drop_down_menu.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/navigation.dart';
import 'package:nextsense_consumer_ui/ui/screens/signal/signal_monitoring_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/signal/visualization_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

/* Screen where the signal can be monitored. */
class SignalMonitoringScreen extends HookWidget {
  static const String id = 'signal_monitoring_screen';

  final Navigation _navigation = getIt<Navigation>();

  SignalMonitoringScreen({super.key});

  Widget dataTypeRadio(SignalMonitoringScreenViewModel viewModel) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 40,
          child: ListTile(
            title: const Text('EEG'),
            leading: Radio(
                value: DataType.eeg,
                groupValue: viewModel.dataType,
                onChanged: (DataType? dataType) {
                  viewModel.dataType = dataType;
                }),
          ),
        ),
        Expanded(
          flex: 35,
          child: ListTile(
            title: const Text('Acc'),
            leading: Radio(
                value: DataType.acceleration,
                groupValue: viewModel.dataType,
                onChanged: (DataType? dataType) {
                  viewModel.dataType = dataType;
                }),
          ),
        ),
        Expanded(
            flex: 15,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await _navigation.navigateTo(VisualizationSettingsScreen.id);
                viewModel.updateFilterSettings();
              },
            ))
      ],
    );
  }

  Widget sliderControl(BuildContext context, Slider slider) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.blue[700],
        inactiveTrackColor: Colors.blue[100],
        trackShape: const RoundedRectSliderTrackShape(),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
        thumbColor: Colors.blueAccent,
        overlayColor: Colors.blue.withAlpha(32),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
        tickMarkShape: const RoundSliderTickMarkShape(),
        activeTickMarkColor: Colors.blue[700],
        inactiveTickMarkColor: Colors.blue[100],
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorColor: Colors.blueAccent,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      child: slider,
    );
  }

  Widget timeWindowSlider(BuildContext context) {
    SignalMonitoringScreenViewModel viewModel = context.read<SignalMonitoringScreenViewModel>();
    return sliderControl(context, Slider(
        value: viewModel.graphTimeWindow.inSeconds.toDouble(),
        min: viewModel.timeWindowMin.inSeconds.toDouble(),
        max: viewModel.timeWindowMax.inSeconds.toDouble(),
        divisions: viewModel.timeWindowMax.inSeconds - viewModel.timeWindowMin.inSeconds,
        label: '${viewModel.graphTimeWindow.inSeconds}',
        onChanged: (value) {
          viewModel.graphTimeWindow = Duration(seconds: value.toInt());
        },
        onChangeEnd: (value) {
          viewModel.graphTimeWindow = Duration(seconds: value.toInt());
        }));
  }

  List<Widget> body(BuildContext context, SignalMonitoringScreenViewModel viewModel) {
    if (viewModel.isBusy) {
      return [const Text('loading data...'),];
    }

    List<Widget> plotWidgets = [
      Expanded(
        flex: 10,
        child: dataTypeRadio(viewModel),
      ),
      Expanded(
        flex: 10,
        child: Row(children: <Widget>[
          Expanded(
            flex: 75,
            child: timeWindowSlider(context),
          ),
          Expanded(
            flex: 25,
            child: Text('${viewModel.graphTimeWindow.inSeconds} seconds'),
          )
        ]),
      ),
    ];
    switch (viewModel.dataType) {
      case DataType.unknown:
      case DataType.eeg:
        plotWidgets += [
          Expanded(
            flex: 10,
            child: Container(
              margin: const EdgeInsets.all(6),
              child: DropDownMenu(
                title: "EEG Channel:",
                value: viewModel.selectedChannel,
                possibleValues: viewModel.eegChannelList,
                labelAbove: false,
                onChanged: (dynamic value) async {
                  viewModel.selectedChannel = value;
                },
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Container(
              margin: const EdgeInsets.all(6),
              child: DropDownMenu(
                title: "Max Amplitude (uV):",
                value: viewModel.eegAmplitudeMicroVolts.toInt(),
                possibleValues: const [10, 25, 50, 100, 250, 500, 1000, 5000, 10000],
                labelAbove: false,
                onChanged: (dynamic value) {
                  viewModel.eegAmplitudeMicroVolts = value.toDouble();
                },
              ),
            ),
          ),
          Expanded(
            flex: 60,
            child: EegFixedPlotData(
              eegData: viewModel.eegData,
              title: 'EEG Channel ${viewModel.selectedChannel}',
              maxAmplitudeMicroVolts: viewModel.eegAmplitudeMicroVolts,
            ),
          ),
        ];
        break;
      case DataType.acceleration:
        plotWidgets += [
          Expanded(
              flex: 70,
              child: Container(
                  margin: const EdgeInsets.all(10),
                  child: AccelerationPlotData(accData: viewModel.accData)))
        ];
        break;
    }
    return plotWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SignalMonitoringScreenViewModel>.reactive(
        viewModelBuilder: () => SignalMonitoringScreenViewModel(),
        onViewModelReady: (viewModel) => viewModel.init(),
        builder: (context, SignalMonitoringScreenViewModel viewModel, child) =>
            PageScaffold(
                showProfileButton: false,
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.white,
                  child: Column(
                    children: body(context, viewModel),
                  ),
                )
            ));
  }
}
