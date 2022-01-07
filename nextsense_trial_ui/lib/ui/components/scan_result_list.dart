import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';

/*
A widget to show a device or a device id (if a name is not available) once
search is completed.
*/
class ScanResult extends StatelessWidget {
  const ScanResult(
      {required Key key, required this.result, required this.onTap}) :
        super(key: key);

  final Map<String, dynamic> result;
  final VoidCallback onTap;

  Widget _deviceStyle(BuildContext context, String name) {
    return Container(
      padding: EdgeInsets.only(left: 40.0, top: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(151, 151, 151, 0.3),
          ),
        ),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.bodyText2,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDeviceTitle(BuildContext context) {
    String deviceName = result[describeEnum(DeviceAttributesFields.name)];
    String deviceMacAddress =
        result[describeEnum(DeviceAttributesFields.macAddress)];
    if (deviceName.length > 0) {
      return _deviceStyle(
          context, deviceName + ' - ' + deviceMacAddress);
    } else {
      return _deviceStyle(context, deviceMacAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildDeviceTitle(context),
    );
  }
}
