package io.nextsense.android.base;

/**
 * Possible {@link Device} states.
 */
public enum DeviceState {
  CONNECTED,  // Connection established to the device but not ready yet to operate in normal mode.
  CONNECTING,  // Trying to connect to the device.
  DISCONNECTED,  // Disconnected from the device.
  DISCONNECTING,  // Disconnecting from the device.
  IN_ERROR,  // Device connected but not responding properly.
  READY  // Device connected and ready to transmit to or receive data from.
}
