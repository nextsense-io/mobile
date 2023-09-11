package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class GetDeviceStatusCommand extends KauaiFirmwareMessage {

  public GetDeviceStatusCommand(int id) {
    super(KauaiFirmwareMessageProto.MessageType.GET_DEVICE_STATUS, id);
  }
}
