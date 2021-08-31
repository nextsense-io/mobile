package io.nextsense.android.base.devices.xenon;

import android.bluetooth.BluetoothGattCharacteristic;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.WriteType;

import java.time.Instant;
import java.util.Arrays;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;

import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.BluetoothException;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.BaseNextSenseDevice;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.utils.Util;

/**
 * Second generation prototype device that was built internally at NextSense.
 * Dual-ear device with cross-ear channels.
 * Provides device information queries, configuration of a few parameters and data streaming.
 */
public class XenonDevice extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX = "Xenon";

  private static final String TAG = XenonDevice.class.getSimpleName();
  private static final int TARGET_MTU = 256;
  private static final int CHANNELS_NUMBER = 8;

  private static final UUID SERVICE_UUID = UUID.fromString("cb577fc4-7260-41f8-8216-3be734c7820a");
  private static final UUID DATA_UUID = UUID.fromString("59e33cfa-497d-4356-bb46-b87888419cb2");

  private final ListeningExecutorService executorService =
      MoreExecutors.listeningDecorator(Executors.newCachedThreadPool());

  private XenonDataParser xenonDataParser;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothGattCharacteristic dataCharacteristic;
  private SettableFuture<DeviceMode> deviceModeFuture;

  // Needed for reflexion when created by Bluetooth device name.
  public XenonDevice() {}

  public XenonDevice(LocalSessionManager localSessionManager) {
    setLocalSessionManager(localSessionManager);
  }

  @Override
  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    super.localSessionManager = localSessionManager;
    xenonDataParser = XenonDataParser.create(getLocalSessionManager());
  }

  @Override
  public void setBluetoothPeripheralProxy(BlePeripheralCallbackProxy proxy) {
    blePeripheralCallbackProxy = proxy;
    blePeripheralCallbackProxy.addPeripheralCallbackListener(bluetoothPeripheralCallback);
  }

  @Override
  public boolean isDataCharacteristic(BluetoothGattCharacteristic characteristic) {
    return dataCharacteristic != null && characteristic.getUuid() == dataCharacteristic.getUuid();
  }

  @Override
  public int getTargetMTU() {
    return TARGET_MTU;
  }

  @Override
  public int getChannelCount() {
    return CHANNELS_NUMBER;
  }

  @Override
  public ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral) {
    this.peripheral = peripheral;
    initializeCharacteristics();
    return executorService.submit(() -> {
      try {
        executeCommandNoResponse(new SetTimeCommand(Instant.now()));
      } catch (ExecutionException e) {
        Log.e(TAG, "Failed to set the time on the device: " + e.getMessage());
        return false;
      } catch (InterruptedException e) {
        Log.e(TAG, "Interrupted when trying to set the time on the device: " + e.getMessage());
        Thread.currentThread().interrupt();
        return false;
      }
      return true;
    });
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {
    this.peripheral = null;
    clearCharacteristics();
  }

  @Override
  public ListenableFuture<DeviceMode> changeMode(DeviceMode targetDeviceMode) {
    // TODO(eric): Check if there is an active future first?
    if (this.deviceMode == targetDeviceMode) {
      return Futures.immediateFuture(targetDeviceMode);
    }
    switch (targetDeviceMode) {
      case STREAMING:
        if (dataCharacteristic == null) {
          return Futures.immediateFailedFuture(
              new IllegalStateException("No characteristic to stream on."));
        }
        deviceModeFuture = SettableFuture.create();
        localSessionManager.startLocalSession(/*cloudSessionId=*/null, /*uploadNeeded=*/true);
        peripheral.setNotify(dataCharacteristic, /*enable=*/true);
        break;
      case IDLE:
        if (dataCharacteristic == null) {
          return Futures.immediateFuture(DeviceMode.IDLE);
        }
        deviceModeFuture = SettableFuture.create();
        writeCharacteristic(dataCharacteristic, new StopStreamingCommand().getCommand());
        break;
      default:
        return Futures.immediateFailedFuture(new UnsupportedOperationException(
            "The " + targetDeviceMode.toString() + " is not supported on this device."));
    }
    return deviceModeFuture;
  }

  private void writeCharacteristic(BluetoothGattCharacteristic characteristic, byte[] value) {
    peripheral.writeCharacteristic(characteristic, value, WriteType.WITHOUT_RESPONSE);
  }

  private void initializeCharacteristics() {
    dataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_UUID);
    checkCharacteristic(dataCharacteristic, SERVICE_UUID, DATA_UUID);
  }

  private void clearCharacteristics() {
    dataCharacteristic = null;
  }

  private void executeCommandNoResponse(XenonFirmwareCommand command) throws
      ExecutionException, InterruptedException {
    blePeripheralCallbackProxy.writeCharacteristic(
        peripheral, dataCharacteristic, command.getCommand()).get();
  }

  private final BluetoothPeripheralCallback bluetoothPeripheralCallback =
      new BluetoothPeripheralCallback() {
    @Override
    public void onNotificationStateUpdate(
        @NonNull BluetoothPeripheral peripheral,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      if (!deviceModeFuture.isDone() && isDataCharacteristic(characteristic)) {
        if (status == GattStatus.SUCCESS) {
          Util.logd(TAG, "Notification updated with success to " +
              peripheral.isNotifying(characteristic));
          if (peripheral.isNotifying(characteristic)) {
            writeCharacteristic(dataCharacteristic, new StartStreamingCommand().getCommand());
          } else {
            localSessionManager.stopLocalSession();
            deviceMode = DeviceMode.IDLE;
            deviceModeFuture.set(DeviceMode.IDLE);
          }
        } else {
          deviceModeFuture.setException(new BluetoothException(
              "Notification state update failed with code " + status));
        }
      }
    }

    @Override
    public void onCharacteristicUpdate(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      try {
        xenonDataParser.parseDataBytes(value, getChannelCount());
      } catch (FirmwareMessageParsingException e) {
        e.printStackTrace();
      }
    }

    @Override
    public void onCharacteristicWrite(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      Util.logv(TAG, "Characteristic write completed with status " + status.toString() +
          " with value: " + Arrays.toString(value));
      // Check mode change result.
      if (characteristic == dataCharacteristic &&
          value.length == XenonFirmwareCommand.COMMAND_SIZE) {
        DeviceMode targetMode;
        byte[] command = Arrays.copyOfRange(value, 0, XenonFirmwareCommand.COMMAND_SIZE);
        if (Arrays.equals(command, XenonMessageType.START_STREAMING.getCode())) {
          targetMode = DeviceMode.STREAMING;
        } else if (Arrays.equals(command, XenonMessageType.STOP_STREAMING.getCode())) {
          targetMode = DeviceMode.IDLE;
        } else {
          // Not an expected value, return.
          return;
        }

        if (status == GattStatus.SUCCESS) {
          if (targetMode == DeviceMode.IDLE) {
            // TODO(eric): Add ~2 seconds delay before stopping the notifications to empty the
            //             device buffer. 36kb of buffer, time can be calculated from frequency *
            //             packet size.
            peripheral.setNotify(dataCharacteristic, /*enable=*/false);
          } else {
            deviceMode = targetMode;
            deviceModeFuture.set(targetMode);
          }
          Util.logd(TAG, "Wrote command to writeData characteristic with success.");
        } else {
          deviceModeFuture.setException(
              new BluetoothException("Failed to change the mode to " + targetMode.name() +
                  ", Bluetooth error code: " + status.name()));
        }
      }
    }
  };
}
