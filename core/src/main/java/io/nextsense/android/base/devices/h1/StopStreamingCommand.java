package io.nextsense.android.base.devices.h1;

import javax.annotation.concurrent.Immutable;

/**
 * Starts streaming of Data from the H1 Device. It also starts recording in the device's SDCARD LOG
 * file.
 */
@Immutable
public final class StopStreamingCommand extends H1FirmwareCommand {

  public StopStreamingCommand() {
    super(H1MessageType.STOP_STREAMING);
  }
}
