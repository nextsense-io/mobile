
// Fields list for the DeviceInternalState object received from the native
// layer.
enum Fields {
  // When the state was sampled in the hardware device.
  timestamp,
  // Battery level in milli volts.
  batteryMilliVolts,
  // If the device is currently busy processing a command.
  busy,
  // If a micro sd card is inserted in the device.
  uSdPresent,
  // If the earbuds hdmi cable is currently connected.
  hdmiCablePresent,
  // If the RTC clock time is set.
  rtcClockSet,
  // If the device is currently capturing samples from the earbuds.
  captureRunning,
  // If the device battery is charging.
  charging,
  // If the battery level is low.
  batteryLow,
  // If the device is logging captured samples to the sd card.
  uSdLoggingEnabled,
  // If the device detected an internal error and cannot operate anymore.
  internalErrorDetected,
  // How many samples were captured since the start of a capture.
  samplesCounter,
  // How many samples are in the BLE queue waiting to be transmitted.
  bleQueueBacklog,
  // How many samples were lost because the ble queue was full.
  lostSamplesCounter,
  // ble RSSI.
  bleRssi,
  // Boolean array indicating if a channel lead is considered to the off
  // (Impedance too high). Channels 1-8 in order.
  leadsOffPositive
}
