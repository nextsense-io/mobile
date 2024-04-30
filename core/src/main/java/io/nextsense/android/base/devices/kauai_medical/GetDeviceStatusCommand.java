package io.nextsense.android.base.devices.kauai_medical;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class GetDeviceStatusCommand extends KauaiMedicalFirmwareMessage {

  public GetDeviceStatusCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.GET_DEVICE_STATUS, id);
  }
}
