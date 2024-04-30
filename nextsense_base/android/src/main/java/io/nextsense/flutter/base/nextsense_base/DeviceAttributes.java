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
  @Expose
  private final String type;
  @Expose
  private final String revision;
  @Expose
  private final String serialNumber;
  @Expose
  private final String firmwareVersionMajor;
  @Expose
  private final String firmwareVersionMinor;
  @Expose
  private final String firmwareVersionBuildNumber;
  @Expose
  private final String earbudsType;
  @Expose
  private final String earbudsRevision;
  @Expose
  private final String earbudsSerialNumber;
  @Expose
  private final String earbudsVersionMajor;
  @Expose
  private final String earbudsVersionMinor;
  @Expose
  private final String earbudsVersionBuildNumber;

  public DeviceAttributes(
      String macAddress, String name, String type, String revision, String serialNumber,
      String firmwareVersionMajor, String firmwareVersionMinor, String firmwareVersionBuildNumber,
      String earbudsType, String earbudsRevision, String earbudsSerialNumber,
      String earbudsVersionMajor, String earbudsVersionMinor, String earbudsVersionBuildNumber) {
    this.macAddress = macAddress;
    this.name = name;
    this.type = type;
    this.revision = revision;
    this.serialNumber = serialNumber;
    this.firmwareVersionMajor = firmwareVersionMajor;
    this.firmwareVersionMinor = firmwareVersionMinor;
    this.firmwareVersionBuildNumber = firmwareVersionBuildNumber;
    this.earbudsType = earbudsType;
    this.earbudsRevision = earbudsRevision;
    this.earbudsSerialNumber = earbudsSerialNumber;
    this.earbudsVersionMajor = earbudsVersionMajor;
    this.earbudsVersionMinor = earbudsVersionMinor;
    this.earbudsVersionBuildNumber = earbudsVersionBuildNumber;
  }

  public String getMacAddress() {
    return macAddress;
  }

  public String getName() {
    return name;
  }

  public String getType() {
    return type;
  }

  public String getRevision() {
    return revision;
  }

  public String getSerialNumber() {
    return serialNumber;
  }

  public String getFirmwareVersionMajor() {
    return firmwareVersionMajor;
  }

  public String getFirmwareVersionMinor() {
    return firmwareVersionMinor;
  }

  public String getFirmwareVersionBuildNumber() {
    return firmwareVersionBuildNumber;
  }

  public String getEarbudsType() {
    return earbudsType;
  }

  public String getEarbudsRevision() {
    return earbudsRevision;
  }

  public String getEarbudsSerialNumber() {
    return earbudsSerialNumber;
  }

  public String getEarbudsVersionMajor() {
    return earbudsVersionMajor;
  }

  public String getEarbudsVersionMinor() {
    return earbudsVersionMinor;
  }

  public String getEarbudsVersionBuildNumber() {
    return earbudsVersionBuildNumber;
  }

}
