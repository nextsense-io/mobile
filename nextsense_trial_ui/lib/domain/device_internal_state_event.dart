import 'package:flutter/foundation.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state.dart';

enum DeviceInternalStateEventType {
  hdmiCableConnected,
  hdmiCableDisconnected,
  usbCableConnected,
  usbCableDisconnected,
  uSdConnected,
  uSdDisconnected,
  uSdFull,
  batteryLow,
  poweringOff,
  unknown
}

/*
 * Represent internal state event coming from native layer.
 * Event is emitted when single field of device internal state is changed.
 */
class DeviceInternalStateEvent {
  final DeviceInternalStateEventType type;
  final dynamic value;

  const DeviceInternalStateEvent(this.type, this.value);

  factory DeviceInternalStateEvent.createFromInternalStateField(String fieldKey, dynamic value) {
    DeviceInternalStateFields field =
        DeviceInternalStateFields.values.asNameMap()[fieldKey]!;
    DeviceInternalStateEventType type = DeviceInternalStateEventType.unknown;

    // TODO(alex): add more event mapping
    switch (field) {
      case DeviceInternalStateFields.uSdPresent:
        type = value ? DeviceInternalStateEventType.uSdConnected :
            DeviceInternalStateEventType.uSdDisconnected;
        break;
      case DeviceInternalStateFields.hdmiCablePresent:
        type = value ? DeviceInternalStateEventType.hdmiCableConnected :
            DeviceInternalStateEventType.hdmiCableDisconnected;
        break;
      default:
        break;
    }

    return DeviceInternalStateEvent(type, value);
  }

  factory DeviceInternalStateEvent.create(DeviceInternalStateEventType eventType, dynamic value) {
    return DeviceInternalStateEvent(eventType, value);
  }

  @override
  bool operator==(Object other) {
      if (identical(this, other))
        return true;

      if (!(other is DeviceInternalStateEvent))
        return false;

      if (this.value is List && other.value is List)
        return listEquals(this.value, other.value);

      return this.value == other.value;
  }

  @override
  String toString() {
    return "DeviceInternalStateChangeEvent(${this.type})";
  }
}