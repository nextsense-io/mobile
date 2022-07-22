import 'package:permission_handler/permission_handler.dart';

class PermissionRequest {
  Permission permission;
  bool required;
  String requestText;
  String? deniedText;
  bool showRequest;

  PermissionRequest({required this.permission, required this.required,
    required this.requestText, this.showRequest = true, this.deniedText});
}

class PermissionsManager {

  List<PermissionRequest> _permissionsNeeded = [
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
        requestText: 'Location permission is needed to connect to your '
            'NextSense device with Bluetooth, please accept the permission in '
            'the popup after pressing continue.',
        deniedText: 'Please try again and allow the location permission. It is '
            'not possible to connect to your NextSense device without it.'),
    PermissionRequest(permission: Permission.ignoreBatteryOptimizations,
        required: false,
        requestText: 'Battery optimizations need to be disabled to ensure that '
            'the data communication with the device is stable when the phone '
            'is not in use. Please slide the permission to ON in the next '
            'screen after pressing continue.'),
  ];

  PermissionsManager() {}

  Future<bool> allPermissionsGranted() async {
    bool granted = true;
    for (PermissionRequest permissionRequest in _permissionsNeeded) {
      if (await permissionRequest.permission.isDenied) {
        granted = false;
        break;
      }
    }
    return granted;
  }

  Future<List<PermissionRequest>> getPermissionsToRequest() async {
    List<PermissionRequest> permissionRequests = [];
    for (PermissionRequest permissionRequest in _permissionsNeeded) {
      if (await permissionRequest.permission.isDenied) {
        permissionRequests.add(permissionRequest);
      }
    }
    return permissionRequests;
  }
}