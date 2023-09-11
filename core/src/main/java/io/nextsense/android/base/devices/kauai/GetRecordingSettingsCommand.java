package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class GetRecordingSettingsCommand extends KauaiFirmwareMessage {

  public GetRecordingSettingsCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.GET_REC_SETTINGS, id);
  }
}
