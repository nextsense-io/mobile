package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class StartRecordingCommand extends KauaiFirmwareMessage {

  public StartRecordingCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.START_RECORDING, id);
  }
}
