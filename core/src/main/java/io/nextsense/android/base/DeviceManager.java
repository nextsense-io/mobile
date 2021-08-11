package io.nextsense.android.base;

import android.util.Log;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Interface to outside clients. Helps to manage the lifecycle of devices and common errors.
 */
public class DeviceManager {
  private static final String TAG = DeviceManager.class.getSimpleName();

  private final DeviceScanner deviceScanner;
  private final Set<DeviceScanner.DeviceScanListener> deviceScanListeners = new HashSet<>();
  private final Set<Device> devices = new HashSet<>();

  public DeviceManager(DeviceScanner deviceScanner) {
    this.deviceScanner = deviceScanner;
  }

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

  public void findDevices(DeviceScanner.DeviceScanListener deviceScanListener) {
    // Return already connected devices first.
    devices.retainAll(getConnectedDevices());
    for (Device connectedDevice : devices) {
      deviceScanListener.onNewDevice(connectedDevice);
    }
    // Add the listener then launch a new scan.
    deviceScanListeners.add(deviceScanListener);
    deviceScanner.findDevices(mainDeviceScanListener);
  }

  public List<Device> getConnectedDevices() {
    List<Device> connectedDevices = new ArrayList<>();
    for (Device device : devices) {
      if (device.getState() == DeviceState.CONNECTING ||
          device.getState() == DeviceState.CONNECTED ||
          device.getState() == DeviceState.READY) {
        connectedDevices.add(device);
      }
    }
    return connectedDevices;
  }

  public void stopFindingDevices(DeviceScanner.DeviceScanListener deviceScanListener) {
    deviceScanner.stopFindingDevices();
    deviceScanListeners.remove(deviceScanListener);
  }

  private final DeviceScanner.DeviceScanListener mainDeviceScanListener =
      new DeviceScanner.DeviceScanListener() {
    @Override
    public void onNewDevice(Device device) {
      devices.remove(device);
      devices.add(device);
      for (DeviceScanner.DeviceScanListener deviceScanListener : deviceScanListeners) {
        deviceScanListener.onNewDevice(device);
      }
    }

    @Override
    public void onScanError(ScanError scanError) {
      for (DeviceScanner.DeviceScanListener deviceScanListener : deviceScanListeners) {
        deviceScanListener.onScanError(scanError);
      }
    }
  };
}
