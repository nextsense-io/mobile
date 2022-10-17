import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';

/*
A widget to show a device or a device id (if a name is not available) once search is completed.
*/
class ScanResult extends StatelessWidget {
  const ScanResult({required Key key, required this.result, required this.onTap,
    this.showMacAddress = false}) : super(key: key);

  final Map<String, dynamic> result;
  final VoidCallback onTap;
  final bool showMacAddress;

  Widget _deviceButton(BuildContext context, String name) {
    return RoundedBackground(
      child: Text(
        name,
        style: Theme.of(context).textTheme.bodyText2,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDeviceTitle(BuildContext context) {
    String deviceName = result[describeEnum(DeviceAttributesFields.name)];
    String deviceMacAddress = result[describeEnum(DeviceAttributesFields.macAddress)];
    if (deviceName.length > 0) {
      String buttonText = showMacAddress ? deviceName + ' - ' + deviceMacAddress : deviceName;
      return _deviceButton(context, buttonText);
    } else {
      // If no name, need to show the MAC address even if not ideal.
      return _deviceButton(context, deviceMacAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClickableZone(
      onTap: onTap,
      child: _buildDeviceTitle(context),
    );
  }
}
