package io.nextsense.android.base.devices.kauai_medical;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class StartRecordingCommand extends KauaiMedicalFirmwareMessage {

  public StartRecordingCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.START_RECORDING, id);
  }
}
