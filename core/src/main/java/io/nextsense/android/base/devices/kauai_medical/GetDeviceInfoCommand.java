package io.nextsense.android.base.devices.kauai_medical;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class GetDeviceInfoCommand extends KauaiMedicalFirmwareMessage {

  public GetDeviceInfoCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.GET_DEVICE_INFO, id);
  }
}
