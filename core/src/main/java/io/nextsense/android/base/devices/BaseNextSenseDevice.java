package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Bundle;

import androidx.annotation.Nullable;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.welie.blessed.BluetoothPeripheral;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;

import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.LocalSessionManager;

public abstract class BaseNextSenseDevice implements NextSenseDevice {

  protected LocalSessionManager localSessionManager;
  protected DeviceMode deviceMode = DeviceMode.IDLE;
  protected BluetoothPeripheral peripheral;
  protected final Set<DeviceInternalStateChangeListener> deviceInternalStateChangeListeners =
      new HashSet<>();
  protected final Set<ControlCharacteristicListener> controlCharacteristicListeners =
      new HashSet<>();

  public LocalSessionManager getLocalSessionManager() {
    return localSessionManager;
  }

  @Override
  public List<String> getAccChannelNames() {
    return Arrays.asList(Acceleration.Channels.ACC_X.getName(),
        Acceleration.Channels.ACC_Y.getName(), Acceleration.Channels.ACC_Z.getName());
  }

  @Override
  public DeviceMode getDeviceMode() {
    return deviceMode;
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig) {
    return startStreaming(uploadToCloud, userBigTableKey, dataSessionId, earbudsConfig,
        new Bundle());
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig, Bundle parameters) {
    return Futures.immediateFuture(false);
  }

  @Override
  public ListenableFuture<Boolean> stopStreaming() {
    return Futures.immediateFuture(false);
  }

  @Override
  public ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral) {
    return connect(peripheral, /*reconnecting=*/false);
  }

  @Override
  public ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral, boolean reconnecting) {
    return Futures.immediateFuture(false);
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {
  }

  @Override
  public ListenableFuture<Boolean> applyDeviceSettings(DeviceSettings deviceSettings) {
    return Futures.immediateFuture(false);
  }

  @Override
  public ListenableFuture<DeviceSettings> loadDeviceSettings() {
    return Futures.immediateFuture(new DeviceSettings());
  }

  protected void checkCharacteristic(BluetoothGattCharacteristic characteristic, UUID serviceUuid,
                                     UUID charUuid) {
    if (characteristic == null) {
      throw new UnsupportedOperationException("Cannot find the service " + serviceUuid.toString() +
          " and/or the characteristic " + charUuid + " on this device.");
    }
  }

  @Override
  public void addOnDeviceInternalStateChangeListener(DeviceInternalStateChangeListener listener) {
    deviceInternalStateChangeListeners.add(listener);
  }

  @Override
  public void removeOnDeviceInternalStateChangeListener(
      DeviceInternalStateChangeListener listener) {
    deviceInternalStateChangeListeners.remove(listener);
  }

  protected void notifyDeviceInternalStateChangeListeners(byte[] deviceInternalState) {
    for (DeviceInternalStateChangeListener listener : deviceInternalStateChangeListeners) {
      listener.onDeviceInternalStateChange(deviceInternalState);
    }
  }

  @Override
  public void writeControlCharacteristic(byte[] bytes) throws
      ExecutionException, InterruptedException, CancellationException {
    throw new UnsupportedOperationException("This device does not support writing to the control " +
        "characteristic.");
  }

  @Override
  public void addControlCharacteristicListener(ControlCharacteristicListener listener) {
    controlCharacteristicListeners.add(listener);
  }

  @Override
  public void removeControlCharacteristicListener(ControlCharacteristicListener listener) {
    controlCharacteristicListeners.remove(listener);
  }
}
