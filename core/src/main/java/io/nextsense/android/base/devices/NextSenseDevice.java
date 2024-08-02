package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Bundle;

import androidx.annotation.Nullable;

import com.google.common.util.concurrent.ListenableFuture;
import com.welie.blessed.BluetoothPeripheral;

import java.util.List;

import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.data.LocalSessionManager;

/**
 * Defines the interface of NextSense devices.
 */
public interface NextSenseDevice {

  interface DeviceInternalStateChangeListener {
    // The internal state is different depending on which device. For Kauai it is a protobuf that
    // needs to be decoded for example.
    void onDeviceInternalStateChange(byte[] deviceInternalState);
  }

  String START_MODE_UPLOAD_TO_CLOUD_PARAM = "start.mode.upload.to.cloud.param";

  // Interface to set the {@link LocalSessionManager} after construction.
  void setLocalSessionManager(LocalSessionManager localSessionManager);

  // Gets the target Bluetooth MTU for this device.
  int getTargetMTU();

  // Gets the maximum number of channels that the device could have.
  int getChannelCount();

  // Gets the list of EEG channel names that the device will stream.
  List<String> getEegChannelNames();

  // Gets the list of accelerometer channel names that the device will stream.
  List<String> getAccChannelNames();

  void setBluetoothPeripheralProxy(BlePeripheralCallbackProxy proxy);

  boolean isDataCharacteristic(BluetoothGattCharacteristic characteristic);

  ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral);

  ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral, boolean reconnecting);

  void disconnect(BluetoothPeripheral peripheral);

  ListenableFuture<Boolean> applyDeviceSettings(DeviceSettings deviceSettings);

  ListenableFuture<DeviceSettings> loadDeviceSettings();

  // Requests an updated device internal state.
  boolean requestDeviceInternalState();

  void addOnDeviceInternalStateChangeListener(
      NextSenseDevice.DeviceInternalStateChangeListener listener);

  void removeOnDeviceInternalStateChangeListener(
      NextSenseDevice.DeviceInternalStateChangeListener listener);

  /**
   * Starts streaming data from the device.
   * @param uploadToCloud upload data to the cloud if true
   * @param userBigTableKey User's BigTable key for eeg data.
   * @param dataSessionId Data Session id for this session.
   * @param parameters device specific parameters
   * @return true if successful, false otherwise
   */
  ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig, Bundle parameters);
  ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig);

  /**
   * Restarts an ongoing stream after a disconnection.
   *
   * @return true if successful, false otherwise
   */
  ListenableFuture<Boolean> restartStreaming();

  /**
   * Stops streaming data from the device.
   * @return true if successful, false otherwise
   */
  ListenableFuture<Boolean> stopStreaming();

  /**
   * Returns the current {@link DeviceMode}.
   * @return DeviceMode
   */
  DeviceMode getDeviceMode();

  /**
   * Returns the current {@link DeviceInfo}.
   * @return DeviceInfo
   */
  DeviceInfo getDeviceInfo();
}
