import 'package:flutter/material.dart';
import 'package:flutter_common/managers/device_manager.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';

class SessionPopScope extends StatelessWidget {
  final Widget child;
  final DeviceManager _deviceManager = getIt<DeviceManager>();

  SessionPopScope({required Widget this.child}) {}

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _deviceManager.disconnectDevice();
          _deviceManager.dispose();
          NextsenseBase.setFlutterActivityActive(false);
          return true;
        },
        child: child);
  }
}