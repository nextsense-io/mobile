package io.nextsense.android.base.ble;

import android.util.Log;

import com.google.common.collect.Maps;
import com.welie.blessed.BluetoothPeripheral;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BluetoothStateManager;
import io.nextsense.android.base.communication.ble.ReconnectionManager;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.utils.Util;

public class BleDeviceManager implements DeviceManager {

  private static final String TAG = BleDeviceManager.class.getSimpleName();

  private final DeviceScanner deviceScanner;
  private final BleCentralManagerProxy centralManagerProxy;
  private final BluetoothStateManager bluetoothStateManager;
  private final NextSenseDeviceManager nextSenseDeviceManager;
  private final Set<DeviceManager.DeviceScanListener> deviceScanListeners = new HashSet<>();
  private final Map<String, Device> devices = Maps.newConcurrentMap();

  public BleDeviceManager(DeviceScanner deviceScanner,
                          BleCentralManagerProxy centralManagerProxy,
                          BluetoothStateManager bluetoothStateManager,
                          NextSenseDeviceManager nextSenseDeviceManager) {
    this.deviceScanner = deviceScanner;
    this.bluetoothStateManager = bluetoothStateManager;
    this.centralManagerProxy = centralManagerProxy;
    this.nextSenseDeviceManager = nextSenseDeviceManager;
  }

  @Override
  public void close() {
    for (Device connectedDevice : getConnectedDevices()) {
      try {
        connectedDevice.disconnect().get(10, TimeUnit.SECONDS);
      } catch (ExecutionException e) {
        Log.w(TAG, "Exception while disconnecting from device " + connectedDevice.getName() +
            " with address " + connectedDevice.getAddress() + ": " + e.getMessage());
      } catch (InterruptedException e) {
        Log.w(TAG, "Interrupted while disconnecting from device " + connectedDevice.getName() +
            " with address " + connectedDevice.getAddress());
        Thread.currentThread().interrupt();
      } catch (TimeoutException e) {
        Log.w(TAG, "Timeout while disconnecting from device " + connectedDevice.getName() +
            " with address " + connectedDevice.getAddress());
      }
    }
  }

  @Override
  public void findDevices(DeviceManager.DeviceScanListener deviceScanListener) {
    // Return already connected devices first.
    for (Device device : devices.values()) {
      if (device.getState() == DeviceState.CONNECTING ||
          device.getState() == DeviceState.CONNECTED ||
          device.getState() == DeviceState.READY) {
        deviceScanListener.onNewDevice(device);
      }
    }
    // Add the listener then launch a new scan.
    deviceScanListeners.add(deviceScanListener);
    deviceScanner.findDevices(mainDeviceScanListener);
  }

  @Override
  public Optional<Device> getDevice(String macAddress) {
    return Optional.ofNullable(devices.get(macAddress));
  }

  @Override
  public List<Device> getConnectedDevices() {
    List<Device> connectedDevices = new ArrayList<>();
    for (Device device : devices.values()) {
      if (device.getState() == DeviceState.CONNECTING ||
          device.getState() == DeviceState.CONNECTED ||
          device.getState() == DeviceState.READY) {
        connectedDevices.add(device);
      }
    }
    return connectedDevices;
  }

  @Override
  public void stopFindingDevices(DeviceManager.DeviceScanListener deviceScanListener) {
    deviceScanner.stopFindingDevices();
    deviceScanListeners.remove(deviceScanListener);
  }

  private final DeviceScanner.DeviceScanListener mainDeviceScanListener =
      new DeviceScanner.DeviceScanListener() {
    @Override
    public void onNewDevice(BluetoothPeripheral peripheral) {
      Util.logd(TAG, "new device " + peripheral.getAddress() + ", present? " +
          devices.containsKey(peripheral.getAddress()));
      if (!devices.containsKey(peripheral.getAddress())) {

        NextSenseDevice nextSenseDevice =
            nextSenseDeviceManager.getDeviceForName(peripheral.getName());
        if (nextSenseDevice == null) {
          return;
        }
        ReconnectionManager reconnectionManager = ReconnectionManager.create(
            centralManagerProxy, bluetoothStateManager, deviceScanner,
            BleDevice.RECONNECTION_ATTEMPTS_INTERVAL);
        Device device = Device.create(
            centralManagerProxy, bluetoothStateManager, nextSenseDevice, peripheral, reconnectionManager);


        devices.putIfAbsent(device.getAddress(), device);
      }
      for (DeviceManager.DeviceScanListener deviceScanListener : deviceScanListeners) {
        deviceScanListener.onNewDevice(devices.get(peripheral.getAddress()));
      }
    }

    @Override
    public void onScanError(ScanError scanError) {
      for (DeviceManager.DeviceScanListener deviceScanListener : deviceScanListeners) {
        deviceScanListener.onScanError(scanError);
      }
    }
  };
}
