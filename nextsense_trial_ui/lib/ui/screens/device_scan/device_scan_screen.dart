import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/underlined_text_button.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/scan_result_list.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/device_scan/device_scan_screen_vm.dart';
import 'package:stacked/stacked.dart';

class DeviceScanScreen extends HookWidget {
  static const String id = 'main_screen';

  final Navigation _navigation = getIt<Navigation>();

  List<ScanResult> scanResultsWidgets = [];

  Future<void> showConnectionError(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Connection Error',
            content: 'Failed to connect to the NextSense device. Make sure it is turned on an try '
                'again. It it still fails, please contact NextSense support.'));
  }

  List<ScanResult> buildScanResultList(DeviceScanScreenViewModel viewModel) {
    return viewModel.scanResultsMap.values
        .map((result) => ScanResult(
            key: Key(result[describeEnum(DeviceAttributesFields.macAddress)]),
            result: result,
            onTap: () => {viewModel.connectToDevice(result)}))
        .toList();
  }

  Widget scanView(DeviceScanScreenViewModel viewModel, resultList) {
    if (viewModel.isScanning) {
      // if (_scanningCount == 100) {
      //   _scanningCount = 0;
      // }
      // ++_scanningCount;
      return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Stack(children: <Widget>[
          // TODO(eric): Try to animate this.
          Center(child: SvgPicture.asset('assets/images/scanning.svg', height: 250)),
          Center(child: Image(image: AssetImage('assets/images/earbuds.png'), width: 180)),
        ]),
        if (!_navigation.canPop())
          UnderlinedTextButton(
              text: 'Not now',
              onTap: () => _navigation.navigateTo(DashboardScreen.id, replace: true)),
      ]);
    } else {
      return Container(height: 500, child: Column(mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 20, child: Center(child:
              UnderlinedTextButton(text: 'Scan', onTap: () => viewModel.startScan()))),
          Expanded(flex: 80, child: ListView(children: resultList)),
        ],
      ));
    }
  }

  Widget buildBody(DeviceScanScreenViewModel viewModel, BuildContext context) {
    scanResultsWidgets = buildScanResultList(viewModel);
    if (viewModel.hasError) {
      showConnectionError(context);
    }
    Widget scanningBody = Container(
      child: Column(
        children: <Widget>[
          Spacer(),
          Padding(
              padding: EdgeInsets.all(10.0),
              child: HeaderText(
                text: 'NextSense Earbuds',
              ),
            ),
          SizedBox(height: 20),
          scanView(viewModel, scanResultsWidgets),
          Spacer(),
        ],
      ),
    );

    Widget connectingBody = Container(
      child: Stack(
        children: <Widget>[
          scanningBody,
          new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: SizedBox(
                  height: 64,
                  width: 64,
                  child: new CircularProgressIndicator(
                    value: null,
                    strokeWidth: 12,
                  ),
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.all(24),
                  child: MediumText(text: 'Connecting...'),
                ),
              )
            ],
          )
        ],
      ),
    );
    return viewModel.isConnecting ? connectingBody : scanningBody;
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DeviceScanScreenViewModel>.reactive(
        viewModelBuilder: () => DeviceScanScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, DeviceScanScreenViewModel viewModel, child) =>
          PageScaffold(
            showBackButton: Navigator.of(context).canPop(),
            showProfileButton: false,
            child: Container(
              child: Center(child: buildBody(viewModel, context)),
          )
    ));
  }
}
