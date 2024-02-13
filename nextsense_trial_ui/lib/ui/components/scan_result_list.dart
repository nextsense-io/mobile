import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:flutter_common/ui/components/rounded_background.dart';

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
    return Padding(padding: EdgeInsets.only(top: 10), child: RoundedBackground(
      child: MediumText(text: name, textAlign: TextAlign.center))
    );
  }

  Widget _buildDeviceTitle(BuildContext context) {
    String deviceName = result[describeEnum(DeviceAttributesFields.name)];
    String deviceMacAddress = result[describeEnum(DeviceAttributesFields.macAddress)];
    if (deviceName.length > 0) {
      String buttonText = showMacAddress ? deviceName + '\n' + deviceMacAddress : deviceName;
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
