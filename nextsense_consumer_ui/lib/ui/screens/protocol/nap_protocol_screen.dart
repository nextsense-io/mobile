import 'package:flutter/material.dart';
import 'package:flutter_common/domain/protocol.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/nap_protocol_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:stacked/stacked.dart';

class NapProtocolScreen extends ProtocolScreen {

  static const String id = 'nap_protocol_screen';

  NapProtocolScreen(Protocol protocol, {super.key}) :
        super(protocol);

  @override
  Widget build(BuildContext context) {
    // Needs to wrap the parent ViewModel as the check is done on direct class
    // type without looking at ancestry.
    return ViewModelBuilder<NapProtocolScreenViewModel>.reactive(
        viewModelBuilder: () => NapProtocolScreenViewModel(protocol),
        onViewModelReady: (protocolViewModel) => protocolViewModel.init(),
        builder: (context, viewModel, child) => ViewModelBuilder<NapProtocolScreenViewModel>
            .reactive(
            viewModelBuilder: () => viewModel,
            onViewModelReady: (viewModel) => {},
            builder: (context, viewModel, child) => WillPopScope(
              onWillPop: () => onBackButtonPressed(context, viewModel),
              child: body(context, viewModel),
            )));
  }
}