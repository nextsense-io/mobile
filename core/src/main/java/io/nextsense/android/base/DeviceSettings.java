package io.nextsense.android.base;

import java.util.List;

/**
 * Mutable {@link Device} settings. Represents the modifiable settings that can be set on the
 * hardware device.
 */
public class DeviceSettings {
  private float eegSamplingRate;
  private float eegStreamingRate;
  private float imuSamplingRate;
  private float imuStreamingRate;
  // List of enabled channels on the device. 0 indexed.
  private List<Integer> enabledChannels;
  // If the device should be ran in impedance mode where it stimulates an electrode to calculate the
  // impedance. Only one channel can be enabled at a time in this mode.
  private boolean impedanceMode;
  // Device sampling frequency divider to obtain the stimulating frequency for impedance
  // calculations. For example, a divider of 10 with a sampling frequency of 500 would give an
  // impedance frequency of 50.
  private int impedanceDivider;

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

  public boolean isImpedanceMode() {
    return impedanceMode;
  }

  public void setImpedanceMode(boolean impedanceMode) {
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
