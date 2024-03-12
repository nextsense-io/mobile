import 'package:flutter/material.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_consumer_ui/managers/sleep_staging_manager.dart';
import 'package:nextsense_consumer_ui/ui/components/light_header_text.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/components/sleep_pie_chart.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/sleep_protocol_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/sleep_protocols_vm.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class SleepProtocolScreen extends ProtocolScreen {

  static const String id = 'sleep_protocol_screen';

  SleepProtocolScreen(Protocol protocol, {super.key}) :
        super(protocol);

  @override
  Widget notRunningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    final SleepStagingManager sleepStagingManager = context.watch<SleepStagingManager>();
    final SleepProtocolScreenViewModel sleepProtocolScreenViewModel =
        viewModel as SleepProtocolScreenViewModel;
    var statusMsg = '';
    if (viewModel.isError) {
      statusMsg = getRecordingCancelledMessage(viewModel);
    } else if (viewModel.protocolCompleted) {
      statusMsg = ' Recording Completed';
    } else {
      statusMsg = ' Recording Cancelled';
    }

    String finishButtonText = 'Go to Tasks';

    if (!viewModel.isError) {
      if (sleepStagingManager.sleepCalculationState == SleepCalculationState.calculating) {
        statusMsg += "\n\nCalculating sleep staging results...";
      } else if (sleepStagingManager.sleepStagingLabels.isNotEmpty) {
        Duration dataDuration = Duration.zero;
        for (SleepStage sleepStage in viewModel.getSleepStages()) {
          dataDuration += sleepStage.duration;
        }
        statusMsg += "\n";
        Duration sessionDuration = Duration(milliseconds: viewModel.milliSecondsElapsed);
        // Remove extra seconds to nearest 30 seconds.
        sessionDuration = Duration(seconds: sessionDuration.inSeconds -
            sessionDuration.inSeconds.remainder(30));
        double dataLossPercent = 100 - (dataDuration.inSeconds / sessionDuration.inSeconds) * 100;
        statusMsg += "\nTotal nap time: ${viewModel.formatDuration(sessionDuration)}";
        statusMsg += "\nTotal data time: ${viewModel.formatDuration(dataDuration)}";
        statusMsg += "\nBLE data loss: ${dataLossPercent.toStringAsPrecision(2)}%\n";
        for (SleepStage sleepStage in viewModel.getSleepStages()) {
          statusMsg += "\n${sleepStage.stage}: ${sleepStage.percent}% "
              "(${viewModel.formatDuration(sleepStage.duration)})";
        }
        finishButtonText = 'Finish';
      }
    }

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
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              LightHeaderText(text: viewModel.protocol.nameForUser + statusMsg,
                  textAlign: TextAlign.center),
              const Spacer(),
              if (sleepStagingManager.sleepStagingLabels.isNotEmpty)
                SizedBox(height: 250,
                    child: SleepPieChart.withData(sleepProtocolScreenViewModel.getSleepStages())),
              const Spacer(),
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
            ]));
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class type without looking
    // at ancestry.
    return ViewModelBuilder<SleepProtocolsViewModel>.reactive(
        viewModelBuilder: () => SleepProtocolsViewModel(protocol),
        onViewModelReady: (protocolViewModel) => protocolViewModel.init(),
        builder: (context, viewModel, child) => ViewModelBuilder<ProtocolScreenViewModel>
            .reactive(
            viewModelBuilder: () => viewModel,
            onViewModelReady: (viewModel) => {},
            builder: (context, viewModel, child) => WillPopScope(
              onWillPop: () => onBackButtonPressed(context, viewModel),
              child: body(context, viewModel),
            )));
  }
}