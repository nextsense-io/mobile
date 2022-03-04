package io.nextsense.flutter.base.nextsense_base;

import com.google.gson.annotations.Expose;

/**
 * Object representing a Device information after a scan.
 */
public class DeviceAttributes {
  @Expose
  private final String macAddress;
  @Expose
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
