package io.nextsense.android.base.emulated;

import androidx.annotation.Nullable;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;

import java.util.Arrays;
import java.util.Objects;
import java.util.concurrent.Executors;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceData;
import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.xenon.XenonDataParser;
import io.nextsense.android.base.utils.Util;

public class EmulatedDevice extends Device {

  private static final String TAG = EmulatedDevice.class.getSimpleName();

  private LocalSessionManager localSessionManager;
  private DeviceSettings deviceSettings;

  public EmulatedDevice() {
  }

  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  @Override
  public String getName() {
    return "EMULATED_BLE_DEVICE";
  }

  @Override
  public String getAddress() {
    return "EE:EE:EE:EE:EE:EE";
  }

  @Override
  public DeviceState getState() {
    return DeviceState.CONNECTED;
  }

  @Override
  public DeviceMode getMode() {
    return DeviceMode.IDLE;
  }

  public boolean requestDeviceState() {
    return true;
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId) {

    Util.logd(TAG, "EmulatedDevice::startStreaming");

    if (localSessionManager != null) {
      localSessionManager.startLocalSession(userBigTableKey, dataSessionId, uploadToCloud,
              getSettings().getEegStreamingRate(), getSettings().getImuStreamingRate());
    }
    return Futures.immediateFuture(true);
  }

  @Override
  public ListenableFuture<Boolean> stopStreaming() {
    Util.logd(TAG, "EmulatedDevice::stopStreaming");

    if (localSessionManager != null) {
      localSessionManager.stopLocalSession();
    }
    return Futures.immediateFuture(true);
  }

  @Override
  public ListenableFuture<Boolean> startImpedance(
      DeviceSettings.ImpedanceMode impedanceMode, @Nullable Integer channelNumber,
      @Nullable Integer frequencyDivider) {
    return null;
  }

  @Override
  public ListenableFuture<Boolean> stopImpedance() {
    return null;
  }

  @Override
  public ListenableFuture<DeviceState> connect(boolean autoReconnect) {
    Util.logd(TAG, "EmulatedDevice::connect");
    return Futures.immediateFuture(DeviceState.READY);
  }

  @Override
  public ListenableFuture<DeviceState> disconnect() {
    return Futures.immediateFuture(DeviceState.DISCONNECTED);
  }

  @Override
  public DeviceInfo getInfo() {
    return new DeviceInfo();
  }

  @Override
  public DeviceSettings getSettings() {
    if (deviceSettings == null) {
      // Taken from XenonDevice
      deviceSettings = new DeviceSettings();
      deviceSettings.setEnabledChannels(Arrays.asList(1, 3, 6, 7, 8));
      deviceSettings.setEegSamplingRate(250);
      deviceSettings.setEegStreamingRate(250);
      deviceSettings.setImuSamplingRate(250);
      deviceSettings.setImuStreamingRate(250);
      deviceSettings.setImpedanceMode(DeviceSettings.ImpedanceMode.OFF);
      deviceSettings.setImpedanceDivider(25);
    }
    return deviceSettings;
  }

  @Override
  public ListenableFuture<Boolean> setSettings(DeviceSettings newDeviceSettings) {
    return Futures.immediateFuture(false);
  }

  @Override
  public DeviceData getData() {
    // not used
    return null;
  }
}
