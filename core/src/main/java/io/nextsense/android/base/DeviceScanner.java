package io.nextsense.android.base;

import android.bluetooth.le.ScanResult;
import androidx.annotation.NonNull;

import com.welie.blessed.BluetoothCentralManagerCallback;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.ScanFailure;

import io.nextsense.android.Config;
import io.nextsense.android.base.ble.BleDeviceManager;
import io.nextsense.android.base.ble.BleDeviceScanner;
import io.nextsense.android.base.ble.EmulatedDeviceManager;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.emulated.EmulatedDeviceScanner;
import io.nextsense.android.base.utils.Util;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static io.nextsense.android.base.utils.Util.logd;

/**
 * Scans for devices and returns the list of {@link Device} that can be connected to.
 */
public interface DeviceScanner {

    /**
     * Callbacks for scanning devices.
     */
    interface DeviceScanListener {

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
         * Called when a new {@link Device} is found.
         * @param device found
         */
        void onNewDevice(Device device);

        /**
         * Called if there is an error while scanning.
         * @param scanError the cause of the error
         */
        void onScanError(ScanError scanError);
    }

    static DeviceScanner create(NextSenseDeviceManager deviceManager,
                                BleCentralManagerProxy centralManagerProxy) {
        if (Config.useEmulatedBle)
            return new EmulatedDeviceScanner();

        return new BleDeviceScanner(deviceManager, centralManagerProxy);
    }

    void close();

    /**
     * Returns the list of valid devices that are detected.
     */
    void findDevices(DeviceScanListener deviceScanListener);

    /**
     * Stops finding devices if it was currently running.
     */
    void stopFindingDevices();
}
