package io.nextsense.flutter.base.nextsense_base;

/**
 * Object representing a Device information after a scan.
 */
public class DeviceAttributes {
  private final String macAddress;
  private final String name;

  public DeviceAttributes(String macAddress, String name) {
    this.macAddress = macAddress;
    this.name = name;
  }

  public String getMacAddress() {
    return macAddress;
  }

  public String getName() {
    return name;
  }
}
