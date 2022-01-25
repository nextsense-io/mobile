import 'package:nextsense_base/nextsense_base.dart';

class Device {
  String macAddress;
  String name;

  Device(this.macAddress, this.name);
}

// Contains the currently connected devices for ease of use.
class DeviceManager {
  Device? _connectedDevice;

  setConnectedDevice(Device? device) {
    _connectedDevice = device;
  }

  Device? getConnectedDevice() {
    return _connectedDevice;
  }

  void disconnectDevice() {
    if (getConnectedDevice() == null) {
      return;
    }
    NextsenseBase.disconnectDevice(getConnectedDevice()!.macAddress);
    setConnectedDevice(null);
  }
}