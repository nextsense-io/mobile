package io.nextsense.android.base.devices.kauai_medical;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class StopRecordingCommand extends KauaiMedicalFirmwareMessage {

  public StopRecordingCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.STOP_RECORDING, id);
  }
}
