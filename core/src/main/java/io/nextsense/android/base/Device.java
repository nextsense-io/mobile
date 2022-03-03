package io.nextsense.android.base;

import androidx.annotation.Nullable;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;

import io.nextsense.android.Config;
import io.nextsense.android.base.ble.BleDevice;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.emulated.EmulatedDevice;

import java.time.Duration;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

/**
 * Main device interface that is shared for any device. Device specific functions are encapsulated
 * in the NextSenseDevice interface which needs to be given at construction time.
 */
public abstract class Device {

  public Device() {}

  public static Device create(BleCentralManagerProxy centralProxy, NextSenseDevice nextSenseDevice,
                              BluetoothPeripheral btPeripheral) {
    if (Config.useEmulatedBle)
      return new EmulatedDevice();

    return new BleDevice(centralProxy, nextSenseDevice, btPeripheral);
  }

  /**
   * Interface to be notified of device changes.
   */
  public interface DeviceStateChangeListener {
    void onDeviceStateChange(DeviceState deviceState);
  }

  public enum DisconnectionStatus {
    NOT_DISCONNECTING,  // Not connected yet.
    BY_REQUEST,  // Disconnect initiated by the user.
    HARD  // Disconnect not initiated by the user.
  }

  private static final String TAG = Device.class.getSimpleName();
  private static final Duration RECONNECTION_ATTEMPTS_INTERVAL = Duration.ofSeconds(30);
  private final Set<DeviceStateChangeListener> deviceStateChangeListeners = new HashSet<>();
  protected SettableFuture<DeviceState> deviceConnectionFuture;
  protected SettableFuture<DeviceState> deviceDisconnectionFuture;

  public abstract String getName();

  public abstract String getAddress();

  public abstract DeviceState getState();

  public abstract DeviceMode getMode();

  public abstract boolean requestDeviceState();

  public abstract ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId);

  public abstract ListenableFuture<Boolean> stopStreaming();

  public abstract ListenableFuture<Boolean> startImpedance(
          DeviceSettings.ImpedanceMode impedanceMode, @Nullable Integer channelNumber,
          @Nullable Integer frequencyDivider);

  public abstract ListenableFuture<Boolean> stopImpedance();

  public void addOnDeviceStateChangeListener(DeviceStateChangeListener listener) {
    deviceStateChangeListeners.add(listener);
  }

  public void removeOnDeviceStateChangeListener(DeviceStateChangeListener listener) {
    deviceStateChangeListeners.remove(listener);
  }

  public void notifyDeviceStateChangeListeners(DeviceState deviceState) {
    for (DeviceStateChangeListener listener : deviceStateChangeListeners) {
      listener.onDeviceStateChange(deviceState);
    }
  }

  /**
   * Tries to connect the device.
   *
   * @param autoReconnect if true will try to reconnect when the connection is lost.
   */
  public abstract ListenableFuture<DeviceState> connect(boolean autoReconnect);

  /**
   * Disconnects the device. Cancels reconnection attempts if autoReconnect was set to true when
   * connecting.
   */
  public abstract ListenableFuture<DeviceState> disconnect();

  /**
   * Gets the {@link DeviceInfo}.
   */
  public abstract DeviceInfo getInfo();

  /**
   * Returns the {@link DeviceSettings} currently in place on the {@link Device}.
   */
  public abstract DeviceSettings getSettings();


  /**
   * Sets the deviceSettings in the device firmware. The device must be in {@code DeviceMode.IDLE}
   * mode when invoking this.
   */
  public abstract ListenableFuture<Boolean> setSettings(DeviceSettings newDeviceSettings);

  /**
   * Methods to get the data or listen to new data.
   */
  public abstract DeviceData getData();

  @Override
  public boolean equals(Object other) {
    if (this == other) return true;
    if (other == null || getClass() != other.getClass()) return false;
    return getAddress().equals(((Device) other).getAddress());
  }

  @Override
  public int hashCode() {
    return Objects.hash(getAddress());
  }
}
