package io.nextsense.android.base.devices.xenon;

import javax.annotation.concurrent.Immutable;

/**
 * Starts streaming of Data from the Xenon Device. It also starts recording in the device's SDCARD
 * LOG file.
 */
@Immutable
public final class StartStreamingCommand extends XenonFirmwareCommand {

  public StartStreamingCommand() {
    super(XenonMessageType.START_STREAMING);
  }
}
