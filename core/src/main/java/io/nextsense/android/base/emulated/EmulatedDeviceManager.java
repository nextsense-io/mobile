package io.nextsense.android.base.ble;

import android.util.Log;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.emulated.EmulatedDevice;

public class EmulatedDeviceManager implements DeviceManager {

    private static final String TAG = EmulatedDeviceManager.class.getSimpleName();

    private final DeviceScanner deviceScanner;
    private final Set<DeviceScanner.DeviceScanListener> deviceScanListeners = new HashSet<>();
    private final List<Device> devices = new ArrayList<>();
    private final LocalSessionManager localSessionManager;

    public EmulatedDeviceManager(DeviceScanner deviceScanner, LocalSessionManager localSessionManager) {
        this.deviceScanner = deviceScanner;
        this.localSessionManager = localSessionManager;
    }

    @Override
    public void close() {
        // Nothing to do here when emulated
    }

    @Override
    public void findDevices(DeviceScanner.DeviceScanListener deviceScanListener) {
        Log.w(TAG, "EmulatedDeviceManager::findDevices");
        Device device = Device.create(null, null, null);
        // Have to pass localSessionManager to emulated device
        ((EmulatedDevice)device).setLocalSessionManager(localSessionManager);
        devices.add(device);
        deviceScanListener.onNewDevice(device);
    }

    @Override
    public List<Device> getConnectedDevices() {
        return devices;
    }

    @Override
    public void stopFindingDevices(DeviceScanner.DeviceScanListener deviceScanListener) {
        // Nothing to do here when emulated
    }

}
