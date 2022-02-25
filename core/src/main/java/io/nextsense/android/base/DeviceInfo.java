package io.nextsense.android.base;

/**
 * Immutable information about a {@link Device}.
 */
public class DeviceInfo {
  public DeviceType getDeviceType() {
    return DeviceType.XENON;
  }

  String getFirmwareVersion() {
    return "1.0";
  }
}
