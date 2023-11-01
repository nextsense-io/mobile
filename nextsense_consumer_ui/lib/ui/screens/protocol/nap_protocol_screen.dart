import 'package:flutter/material.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_consumer_ui/ui/components/light_header_text.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/components/sleep_pie_chart.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/nap_protocol_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:stacked/stacked.dart';

class NapProtocolScreen extends ProtocolScreen {

  static const String id = 'nap_protocol_screen';

  NapProtocolScreen(Protocol protocol, {super.key}) :
        super(protocol);

  @override
  Widget notRunningStateBody(BuildContext context, ProtocolScreenViewModel viewModel) {
    NapProtocolScreenViewModel napViewModel = (viewModel as NapProtocolScreenViewModel);
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
      if (napViewModel.sleepCalculationState == SleepCalculationState.calculating) {
        statusMsg += "\n\nCalculating sleep staging results...";
      } else if (napViewModel.sleepCalculationState == SleepCalculationState.calculated) {
        statusMsg += "\n\nResult: ${napViewModel.sleepStagingLabels![0]}\n";
        statusMsg += "Confidence: ${napViewModel.sleepStagingConfidences![0]}";
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
              if (napViewModel.sleepCalculationState == SleepCalculationState.calculated)
                SizedBox(height: 250, child: SleepPieChart.withSampleData()),
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

    // Re-add status messages.
    // Container(
    //   child: Visibility(
    //     visible: viewModel.hasError,
    //       child: Column(
    //         children: [
    //           Text(viewModel.modelError ?? "",
    //             style: TextStyle(color: Colors.white),
    //            )
    //           ],
    //       ),
    //   ),
    // ),
  }

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class type without looking
    // at ancestry.
    return ViewModelBuilder<NapProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => NapProtocolScreenViewModel(protocol),
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