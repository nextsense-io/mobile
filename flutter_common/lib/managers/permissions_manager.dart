import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequest {
  final Permission permission;
  final bool required;
  final String requestText;
  final String? deniedText;
  final bool showRequest;
  final int minApiVersion;

  const PermissionRequest({required this.permission, required this.required,
    required this.requestText, this.showRequest = true, this.deniedText, this.minApiVersion = 1});
}

class PermissionsManager {

  static const List<PermissionRequest> basicPermissionsNeeded = [
    PermissionRequest(permission: Permission.bluetoothScan, required: true,
        requestText: 'Bluetooth scan permission is needed to find your '
            'NextSense device, please accept the permission in the popup after '
            'pressing continue.',
        deniedText: 'Please try again and allow the Bluetooth scan permission. '
            'It is not possible to find your NextSense device without it.'),
    PermissionRequest(permission: Permission.bluetoothConnect, required: false, showRequest: false,
        requestText: 'Bluetooth connect permission is needed to connect to '
            'your NextSense device, please accept the permission in the popup '
            'after pressing continue.',
        deniedText: 'Please try again and allow the bluetooth connect '
            'permission. It is not possible to connect to your NextSense '
            'device without it.'),
    PermissionRequest(permission: Permission.locationWhenInUse, required: true,
        requestText: 'Location permission is needed to pair your NextSense device with the app. '
            'Please accept the permission to enable location use after you press "Continue".',
        deniedText: 'Please try again and allow the location permission. It is '
            'not possible to pair to your NextSense device without it.'),
    PermissionRequest(permission: Permission.notification, required: true,
        requestText: 'Notifications are needed to show the status of the device and of the '
            'recording.',
        deniedText: 'Please try again and allow the notification permission. It is '
            'not possible to manage your NextSense device without it.', minApiVersion: 33),
    PermissionRequest(permission: Permission.ignoreBatteryOptimizations,
        required: false,
        requestText: 'Battery Optimization needs to be disabled to allow for EEG data collection '
            'and communication with the device. Please "Allow" permission for the NextSense app to '
            'run in the background after you press "Continue."'),
  ];

  late List<PermissionRequest> permissionsNeeded;

  PermissionsManager({this.permissionsNeeded = basicPermissionsNeeded});

  Future<bool> allPermissionsGranted() async {
    bool granted = true;
    for (PermissionRequest permissionRequest in permissionsNeeded) {
      if (!(await permissionRequest.permission.isGranted)) {
        granted = false;
        break;
      }
    }
    return granted;
  }

  Future<List<PermissionRequest>> getPermissionsToRequest() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    List<PermissionRequest> permissionRequests = [];
    for (PermissionRequest permissionRequest in permissionsNeeded) {
      if (androidInfo.version.sdkInt! < permissionRequest.minApiVersion!) {
        continue;
      }
      if (!(await permissionRequest.permission.isGranted)) {
        permissionRequests.add(permissionRequest);
      }
    }
    return permissionRequests;
  }
}