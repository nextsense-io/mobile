package io.nextsense.android.base;

import com.welie.blessed.BluetoothPeripheral;

import io.nextsense.android.Config;
import io.nextsense.android.base.ble.BleDeviceScanner;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BluetoothStateManager;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.emulated.EmulatedDeviceScanner;

/**
 * Scans for devices and returns the list of {@link Device} that can be connected to.
 */
public interface DeviceScanner {

    enum ScanError {
        // Placeholder if reason is not assigned yet.
        UNDEFINED,
        // Bluetooth is not enabled, scan can't be completed.
        BT_DISABLED,
        // Internal error in the Android Bluetooth stack. Should try to restart it.
        INTERNAL_BT_ERROR,
        // Permission not granted. Ask the user again.
        PERMISSION_ERROR,
        // Cannot scan due to a config issue, should report the issue for further debugging.
        FATAL_ERROR
    }

    /**
     * Callbacks for scanning devices.
     */
    interface DeviceScanListener {

        /**
         * Called when a new {@link BluetoothPeripheral} is found.
         * @param peripheral found
         */
        void onNewDevice(BluetoothPeripheral peripheral);

        /**
         * Called if there is an error while scanning.
         * @param scanError the cause of the error
         */
        void onScanError(ScanError scanError);
    }

    /**
     * Callbacks for scanning peripherals.
     */
    interface PeripheralScanListener {

        /**
         * Called when a new {@link BluetoothPeripheral} is found.
         * @param peripheral found
         */
        void onNewPeripheral(BluetoothPeripheral peripheral);

        /**
         * Called if there is an error while scanning.
         * @param scanError the cause of the error
         */
        void onScanError(ScanError scanError);
    }

    static DeviceScanner create(NextSenseDeviceManager deviceManager,
                                BleCentralManagerProxy centralManagerProxy,
                                BluetoothStateManager bluetoothStateManager) {
        if (Config.USE_EMULATED_BLE)
            return new EmulatedDeviceScanner();

        return new BleDeviceScanner(deviceManager, centralManagerProxy, bluetoothStateManager);
    }

    void close();

    /**
     * Returns the list of valid devices that are detected.
     */
    void findDevices(DeviceScanListener deviceScanListener);

    /**
     * Returns the list of valid peripherals that are detected.
     */
    void findPeripherals(PeripheralScanListener peripheralScanListener);

    /**
     * Stops finding devices or peripherals if it was currently running.
     */
    void stopFinding();
}
