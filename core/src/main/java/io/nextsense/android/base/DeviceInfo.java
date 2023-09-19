package io.nextsense.android.base;

import com.google.gson.annotations.Expose;

/**
 * Immutable information about a {@link Device}.
 */
public class DeviceInfo {
  public static String UNKNOWN = "unknown";
  @Expose
  private DeviceType type;
  @Expose
  private String revision;
  @Expose
  private String serialNumber;
  @Expose
  private String firmwareVersionMajor;
  @Expose
  private String firmwareVersionMinor;
  @Expose
  private String firmwareVersionBuildNumber;
  @Expose
  private String earbudsType;
  @Expose

  private String earbudsRevision;
  @Expose
  private String earbudsSerialNumber;
  @Expose
  private String earbudsVersionMajor;
  @Expose
  private String earbudsVersionMinor;
  @Expose
  private String earbudsVersionBuildNumber;

  public DeviceInfo(
      DeviceType type,
      String revision,
      String serialNumber,
      String firmwareVersionMajor,
      String firmwareVersionMinor,
      String firmwareVersionBuildNumber,
      String earbudsType,
      String earbudsRevision,
      String earbudsSerialNumber,
      String earbudsVersionMajor,
      String earbudsVersionMinor,
      String earbudsVersionBuildNumber) {
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

  public DeviceType getType() {
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
