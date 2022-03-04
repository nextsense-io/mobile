package io.nextsense.android.base;

import com.google.gson.annotations.Expose;

import java.util.ArrayList;
import java.util.List;

/**
 * Mutable {@link Device} settings. Represents the modifiable settings that can be set on the
 * hardware device.
 */
public class DeviceSettings {

  // TODO(eric): Should have device specific modes.
  public enum ImpedanceMode {
    OFF((byte)0x00),
    ON_EXTERNAL_CURRENT((byte)0x01),
    ON_1299_DC((byte)0x02),
    ON_1299_AC((byte)0x03);

    private final byte code;

    ImpedanceMode(byte code) {
      this.code = code;
    }

    public byte getCode() {
      return code;
    }
  }

  @Expose
  private float eegSamplingRate;
  @Expose
  private float eegStreamingRate;
  @Expose
  private float imuSamplingRate;
  @Expose
  private float imuStreamingRate;
  // List of enabled channels on the device. 0 indexed.
  @Expose
  private List<Integer> enabledChannels;
  // If the device should be ran in impedance mode where it stimulates an electrode to calculate the
  // impedance. Only one channel can be enabled at a time in this mode.
  @Expose
  private ImpedanceMode impedanceMode;
  // Device sampling frequency divider to obtain the stimulating frequency for impedance
  // calculations. For example, a divider of 10 with a sampling frequency of 500 would give an
  // impedance frequency of 50.
  @Expose
  private int impedanceDivider;

  public DeviceSettings(DeviceSettings deviceSettings) {
    this.eegSamplingRate = deviceSettings.eegSamplingRate;
    this.eegStreamingRate = deviceSettings.eegStreamingRate;
    this.imuSamplingRate = deviceSettings.imuSamplingRate;
    this.imuStreamingRate = deviceSettings.imuStreamingRate;
    this.enabledChannels = new ArrayList<>();
    this.enabledChannels.addAll(deviceSettings.enabledChannels);
    this.impedanceMode = deviceSettings.impedanceMode;
    this.impedanceDivider = deviceSettings.impedanceDivider;
  }

  public DeviceSettings() {}

  public float getEegSamplingRate() {
    return eegSamplingRate;
  }

  public float getEegStreamingRate() {
    return eegStreamingRate;
  }

  public float getImuSamplingRate() {
    return imuSamplingRate;
  }

  public float getImuStreamingRate() {
    return imuStreamingRate;
  }

  public List<Integer> getEnabledChannels() {
    return enabledChannels;
  }

  public void setEnabledChannels(List<Integer> enabledChannels) {
    this.enabledChannels = enabledChannels;
  }

  public ImpedanceMode getImpedanceMode() {
    return impedanceMode;
  }

  public void setImpedanceMode(ImpedanceMode impedanceMode) {
    this.impedanceMode = impedanceMode;
  }

  public int getImpedanceDivider() {
    return impedanceDivider;
  }

  public void setImpedanceDivider(int impedanceDivider) {
    this.impedanceDivider = impedanceDivider;
  }

  /**
   * Returns true and sets the value if it is valid for the device, false otherwise.
   */
  public boolean setEegSamplingRate(float hertz) {
    eegSamplingRate = hertz;
    return true;
  }

  public boolean setEegStreamingRate(float hertz) {
    eegStreamingRate = hertz;
    return true;
  }

  public boolean setImuStreamingRate(float hertz) {
    imuStreamingRate = hertz;
    return true;
  }

  public boolean setImuSamplingRate(float hertz) {
    imuSamplingRate = hertz;
    return true;
  }
}
