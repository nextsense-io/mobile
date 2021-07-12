package io.nextsense.android.base;

/**
 * Mutable {@link Device} settings.
 */
public class DeviceSettings {

  public float getEegSamplingRate() {
    return 0;
  }

  public float getEegStreamingRate() {
    return 0;
  }

  public float getImuSamplingRate() {
    return 0;
  }

  public float getImuStreamingRate() {
    return 0;
  }

  /**
   * Returns true and sets the value if it is valid for the device, false otherwise.
   */
  public boolean setEegSamplingRate(float hertz) {
    return false;
  }

  public boolean setEegStreamingRate(float hertz) {
    return false;
  }

  public boolean setImuStreamingRate(float hertz) {
    return false;
  }

  public boolean setImuSamplingRate(float hertz) {
    return false;
  }

}
