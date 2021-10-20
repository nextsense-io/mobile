package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Bundle;

import com.google.common.util.concurrent.ListenableFuture;
import com.welie.blessed.BluetoothPeripheral;

import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.data.LocalSessionManager;

/**
 * Defines the interface of NextSense devices.
 */
public interface NextSenseDevice {

  String START_MODE_UPLOAD_TO_CLOUD_PARAM = "start.mode.upload.to.cloud.param";

  // Interface to set the {@link LocalSessionManager} after construction.
  void setLocalSessionManager(LocalSessionManager localSessionManager);

  // Gets the target Bluetooth MTU for this device.
  int getTargetMTU();

  // Gets the maximum number of channels that the device could have.
  int getChannelCount();

  void setBluetoothPeripheralProxy(BlePeripheralCallbackProxy proxy);

  boolean isDataCharacteristic(BluetoothGattCharacteristic characteristic);

  ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral);

  void disconnect(BluetoothPeripheral peripheral);

  ListenableFuture<Boolean> applyDeviceSettings(DeviceSettings deviceSettings);

  ListenableFuture<DeviceSettings> loadDeviceSettings();

  /**
   * Starts streaming data from the device.
   * @param uploadToCloud upload data to the cloud if true
   * @param parameters device specific parameters
   * @return true if successful, false otherwise
   */
  ListenableFuture<Boolean> startStreaming(boolean uploadToCloud, Bundle parameters);
  ListenableFuture<Boolean> startStreaming(boolean uploadToCloud);

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
}
