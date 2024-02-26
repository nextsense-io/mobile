package io.nextsense.android.base.devices.kauai;

import javax.annotation.concurrent.Immutable;

/**
 * Stops streaming of Data from the Xenon Device. It also stops recording in the device's SDCARD
 * LOG file.
 */
@Immutable
public final class StopStreamingCommand extends KauaiFirmwareCommand {

  public StopStreamingCommand() {
    super(KauaiMessageType.STOP_STREAMING);
  }
}
