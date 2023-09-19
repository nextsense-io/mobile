import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/components/small_text.dart';
import 'package:nextsense_trial_ui/ui/components/wait_widget.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/support/support_screen_vm.dart';
import 'package:stacked/stacked.dart';

class SupportScreen extends HookWidget {
  static const String id = 'support_screen';

  Widget getDeviceInfo(SupportScreenViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: NextSenseColors.darkBlue,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(top: 20),
      child: SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediumText(text: 'Device Info', color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Device Type: ${viewModel.connectedDevice!.type.toString().split('.').last}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Device Revision: ${viewModel.connectedDevice!.revision}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Device Serial Number: ${viewModel.connectedDevice!.serialNumber}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Firmware Major Version: ${viewModel.connectedDevice!.firmwareVersionMajor}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Firmware Minor Version: ${viewModel.connectedDevice!.firmwareVersionMinor}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text:
                  'Firmware Build Number: ${viewModel.connectedDevice!.firmwareVersionBuildNumber}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Earbuds Type: ${viewModel.connectedDevice!.earbudsType}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Earbuds Revision: ${viewModel.connectedDevice!.earbudsRevision}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text: 'Earbuds Serial Number: ${viewModel.connectedDevice!.earbudsSerialNumber}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text:
                  'Earbuds Firmware Version Major: ${viewModel.connectedDevice!.earbudsVersionMajor}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text:
                  'Earbuds Firmware Version Minor: ${viewModel.connectedDevice!.earbudsVersionMinor}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
          SmallText(
              text:
                  'Earbuds Firmware Build Number: ${viewModel.connectedDevice!.earbudsVersionBuildNumber}',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 10),
        ],
      ),
    ));
  }

  Widget buildBody(SupportScreenViewModel viewModel, BuildContext context) {
    return Column(children: [
      HeaderText(text: 'Support'),
      SizedBox(height: 20),
      MediumText(
          text: 'Application version: ${viewModel.version ?? ''}', color: NextSenseColors.darkBlue),
      SizedBox(height: 20),
      if (viewModel.isBusy)
        WaitWidget(message: 'Submitting your issue...')
      else
        TextField(
            keyboardType: TextInputType.multiline,
            minLines: 5,
            maxLines: null,
            decoration: InputDecoration(
              label: MediumText(text: 'Describe your issue'),
              filled: true,
              fillColor: Colors.white,
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: NextSenseColors.purple,
                ),
              ),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              viewModel.issueDescription = text;
            }),
      SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MediumText(text: 'Attach application logs', color: NextSenseColors.darkBlue),
          Switch(
            activeColor: NextSenseColors.darkBlue,
            value: viewModel.attachLog,
            onChanged: (value) {
              viewModel.attachLog = value;
              viewModel.notifyListeners();
            },
          ),
        ],
      ),
      SizedBox(height: 10),
      SimpleButton(
          text: MediumText(text: 'Submit Issue', color: NextSenseColors.darkBlue),
          onTap: () async => {
                if (viewModel.issueDescription != null && viewModel.issueDescription!.isNotEmpty)
                  {
                    if (await viewModel.submitIssue())
                      {
                        showDialog(
                            context: context,
                            builder: (_) => SimpleAlertDialog(
                                title: 'Issue submitted', popNavigator: true, content: ''))
                      }
                    else
                      {
                        showDialog(
                            context: context,
                            builder: (_) => SimpleAlertDialog(
                                title: 'Failed to submit',
                                content: 'There was an issue when trying to submit your issue. '
                                    'Please make sure your internet connection is working and try '
                                    'again.'))
                      }
                  }
                else
                  {
                    showDialog(
                        context: context,
                        builder: (_) => SimpleAlertDialog(
                            title: 'No description',
                            content:
                                'Please describe the issue and what you did before it happened.'))
                  }
              }),
      viewModel.connectedDevice != null ? getDeviceInfo(viewModel) : SizedBox(),
      Spacer()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SupportScreenViewModel>.reactive(
        viewModelBuilder: () => SupportScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, SupportScreenViewModel viewModel, child) => PageScaffold(
              showBackButton: true,
              showProfileButton: false,
              child: Center(child: buildBody(viewModel, context)),
            ));
  }
}
