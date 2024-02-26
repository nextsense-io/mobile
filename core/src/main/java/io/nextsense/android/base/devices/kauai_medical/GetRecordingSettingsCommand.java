package io.nextsense.android.base.devices.kauai_medical;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class GetRecordingSettingsCommand extends KauaiMedicalFirmwareMessage {

  public GetRecordingSettingsCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.GET_RECORDING_SETTINGS, id);
  }
}
