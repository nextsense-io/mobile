import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/dialogs/start_adhoc_protocol_dialog_vm.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_mapping.dart';
import 'package:stacked/stacked.dart';

class StartAdhocProtocolDialog extends HookWidget {
  StartAdhocProtocolDialog({Key? key}) : super(key: key);

  final Navigation _navigation = getIt<Navigation>();

  Widget _buildBody(context, viewModel) {
    List<Widget> options = viewModel
        .getAdhocProtocols()
        .map<Widget>((adhocSession) => Padding(
              padding: EdgeInsets.all(15),
              child: SimpleButton(
                  text: MediumText(
                      text: adhocSession.protocol.nameForUser, color: NextSenseColors.darkBlue),
                  onTap: () async {
                    ProtocolType protocolType = protocolTypeFromString(adhocSession.protocol.type);
                    await _navigation.navigateWithCapabilityChecking(context,
                        ProtocolScreenMapping.getProtocolScreenId(protocolType),
                        arguments: adhocSession);
                    _navigation.pop();
                  }),
            ))
        .toList();

    return SimpleDialog(
      title: HeaderText(text: 'Select adhoc protocol to start'),
      children: options,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StartAdhocProtocolDialogViewModel>.nonReactive(
        viewModelBuilder: () => StartAdhocProtocolDialogViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return _buildBody(context, viewModel);
        });
  }
}
