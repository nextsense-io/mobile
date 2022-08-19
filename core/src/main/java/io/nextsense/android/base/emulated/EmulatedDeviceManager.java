package io.nextsense.android.base.emulated;

import android.util.Log;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.emulated.EmulatedDevice;

public class EmulatedDeviceManager implements DeviceManager {

    // Changes in those commands should respect EmulatorCommand enum in nextsense_base.dart
    public static final String EMULATOR_COMMAND_CONNECT = "CONNECT";
    public static final String EMULATOR_COMMAND_DISCONNECT = "DISCONNECT";
    public static final String EMULATOR_COMMAND_INTERNAL_STATE_CHANGE = "INTERNAL_STATE_CHANGE";

    private static final String TAG = EmulatedDeviceManager.class.getSimpleName();

    private final DeviceScanner deviceScanner;
    private final Set<DeviceScanner.DeviceScanListener> deviceScanListeners = new HashSet<>();
    private final List<Device> devices = new ArrayList<>();
    private final LocalSessionManager localSessionManager;
    private EmulatedDevice emulatedDevice;

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
        emulatedDevice = (EmulatedDevice) Device.create(null, null, null, null, null);
        // Have to pass localSessionManager to emulated device
        emulatedDevice.setLocalSessionManager(localSessionManager);
        devices.add(emulatedDevice);
        deviceScanListener.onNewDevice(emulatedDevice);
    }

    @Override
    public List<Device> getConnectedDevices() {
        return devices;
    }

    @Override
    public void stopFindingDevices(DeviceScanner.DeviceScanListener deviceScanListener) {
        // Nothing to do here when emulated
    }

    public void sendEmulatorCommand(String command, Map<String, Object> params) {
        Log.w(TAG, "sendEmulatorCommand " + command + " " + params);
        switch (command) {
            case EMULATOR_COMMAND_DISCONNECT:
                emulatedDevice.emulateDisconnect();
                break;
            case EMULATOR_COMMAND_CONNECT:
                emulatedDevice.emulateConnect();
                break;
            case EMULATOR_COMMAND_INTERNAL_STATE_CHANGE:
                emulatedDevice.emulateInternalStateChange(params);
                break;
        }
    }
}
