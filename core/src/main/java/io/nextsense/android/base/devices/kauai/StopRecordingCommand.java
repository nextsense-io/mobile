package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class StopRecordingCommand extends KauaiFirmwareMessage {

  public StopRecordingCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.STOP_RECORDING, id);
  }
}
