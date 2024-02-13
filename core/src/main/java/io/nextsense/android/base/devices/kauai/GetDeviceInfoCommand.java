package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class GetDeviceInfoCommand extends KauaiFirmwareMessage {

  public GetDeviceInfoCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.GET_DEVICE_INFO, id);
  }
}
