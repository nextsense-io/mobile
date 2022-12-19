import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/components/error_overlay.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/components/underlined_text_button.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/scan_result_list.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/device_scan/device_scan_screen_vm.dart';
import 'package:stacked/stacked.dart';

class DeviceScanScreen extends HookWidget {
  static const String id = 'main_screen';

  final Navigation _navigation = getIt<Navigation>();
  final bool autoConnect;

  List<ScanResult> scanResultsWidgets = [];

  DeviceScanScreen({this.autoConnect = false});

  Future<void> showConnectionError(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Connection Error',
            content: 'Failed to connect to the NextSense device. Make sure it is turned on an try '
                'again. It it still fails, please contact NextSense support.'));
  }

  List<ScanResult> buildScanResultList(DeviceScanScreenViewModel viewModel) {
    bool showMacAddress = viewModel.scanResultsMap.length > 1 ? true : false;
    return viewModel.scanResultsMap.values
        .map((result) => ScanResult(
            key: Key(result[describeEnum(DeviceAttributesFields.macAddress)]),
            result: result, showMacAddress: showMacAddress,
            onTap: () => {viewModel.connectToDevice(result)}))
        .toList();
  }

  Widget _scanView(DeviceScanScreenViewModel viewModel, resultList) {
    switch (viewModel.scanningState) {
      case ScanningState.NO_BLUETOOTH:
        // An overlay will appear with instructions on how to enable Bluetooth.
        return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Stack(children: <Widget>[
            Center(child: Image(image: AssetImage('assets/images/earbuds.png'), width: 180)),
          ]),
        ]);
      case ScanningState.SCANNING_NO_RESULTS:
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
          UnderlinedTextButton(
              text: 'Not now',
              onTap: () => _navigation.navigateToNextRoute()),
        ]);
      case ScanningState.CONNECTING:
      // Fallthrough, an overlay will appear on top of the results.
      case ScanningState.SCANNING_WITH_RESULTS:
        return Container(height: 500, child: ListView(children: resultList));
      case ScanningState.FINISHED_SCAN:
        return Container(
            height: 500,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    flex: 20,
                    child: Center(
                        child: UnderlinedTextButton(
                            text: 'Scan again', onTap: () => viewModel.startScan()))),
                Expanded(flex: 80, child: ListView(children: resultList)),
              ],
            ));
      case ScanningState.CONNECTED:
        return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Center(child: Image(image: AssetImage('assets/images/earbuds.png'), width: 180)),
          SizedBox(height: 20),
          SimpleButton(
              text: MediumText(text: 'Continue', color: NextSenseColors.darkBlue),
              onTap: () => _navigation.navigateToNextRoute()),
          SizedBox(height: 20),
          SvgPicture.asset('assets/images/circle_checked_blue.svg',
              semanticsLabel: 'connected', height: 60),
          SizedBox(height: 20),
        ]);
      case ScanningState.NOT_FOUND_OR_ERROR:
        return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Center(child: Image(image: AssetImage('assets/images/earbuds.png'), width: 180)),
          SizedBox(height: 20),
          Icon(Icons.cancel, size: 60, color: NextSenseColors.red),
          SizedBox(height: 20),
          EmphasizedText(text: 'Pairing failed'),
          SizedBox(height: 20),
          MediumText(
              text: 'NextSense earbuds failed to connect. Please make sure your device is '
                  'charged and turned on.',
              color: NextSenseColors.darkBlue),
          SizedBox(height: 20),
          SimpleButton(
              text: MediumText(text: 'Try again', color: NextSenseColors.darkBlue),
              onTap: () => viewModel.startScan()),
          SizedBox(height: 20),
          UnderlinedTextButton(
              text: 'Not now',
              onTap: () => _navigation.navigateToNextRoute()),
        ]);
    }
  }

  Widget _scanningBody(DeviceScanScreenViewModel viewModel) {
    return Container(
      child: Column(
        children: <Widget>[
          Spacer(),
          Padding(
            padding: EdgeInsets.all(10.0),
            child: HeaderText(text: 'NextSense Earbuds'),
          ),
          SizedBox(height: 20),
          _scanView(viewModel, scanResultsWidgets),
          Spacer(),
        ],
      ),
    );
  }

  Widget _noBluetoothOverlay(BuildContext context, DeviceScanScreenViewModel viewModel) {
    return Column(children: [
      Spacer(),
      ErrorOverlay(
          child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Padding(
          padding: EdgeInsets.all(10.0),
          child: MediumText(
              text: 'Bluetooth is not enabled in your device, please turn it on to be able to '
                  'connect to your NextSense device',
              color: NextSenseColors.darkBlue),
        ),
        Padding(
            padding: EdgeInsets.all(10.0),
            child: SimpleButton(
              text: MediumText(text: 'Open Bluetooth Settings', color: NextSenseColors.darkBlue),
              onTap: () async {
                // Check if Bluetooth is ON.
                AppSettings.openBluetoothSettings();
              },
            )),
        Padding(
            padding: EdgeInsets.all(10.0),
            child: SimpleButton(
              text: MediumText(text: 'Continue', color: NextSenseColors.darkBlue),
              onTap: () async {
                bool bluetoothEnabled = await viewModel.startScanIfPossible();
                if (!bluetoothEnabled) {
                  await showDialog(
                      context: context,
                      builder: (_) => SimpleAlertDialog(
                          title: 'No Bluetooth',
                          content: 'You need to enable Bluetooth to start finding your device.'));
                }
              },
            )),
      ]))),
      Spacer()
    ]);
  }

  Widget _connectingOverlay() {
    return Column(
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
    );
  }

  Widget buildBody(DeviceScanScreenViewModel viewModel, BuildContext context) {
    scanResultsWidgets = buildScanResultList(viewModel);
    Future.delayed(Duration.zero, () {
      if (viewModel.hasError) {
        showConnectionError(context);
      }
    });

    switch (viewModel.scanningState) {
      case ScanningState.CONNECTING:
        return Container(
          child: Stack(
            children: <Widget>[
              _scanningBody(viewModel),
              _connectingOverlay(),
            ],
          ),
        );
      case ScanningState.NO_BLUETOOTH:
        return Container(
          child: Stack(
            children: <Widget>[
              _scanningBody(viewModel),
              _noBluetoothOverlay(context, viewModel),
            ],
          ),
        );
      default:
        return _scanningBody(viewModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DeviceScanScreenViewModel>.reactive(
        viewModelBuilder: () => DeviceScanScreenViewModel(autoConnect: autoConnect),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, DeviceScanScreenViewModel viewModel, child) => PageScaffold(
            showBackButton: Navigator.of(context).canPop(),
            showProfileButton: false,
            child: Container(
              child: Center(child: buildBody(viewModel, context)),
            )));
  }
}
