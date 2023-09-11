package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class SetDateTimeCommand extends KauaiFirmwareMessage {

  public SetDateTimeCommand(int id, String dateTime) {
    super(KauaiFirmwareMessageProto.MessageType.SET_DATE_TIME, id);
    getBuilder().setCurrentTime(
        KauaiFirmwareMessageProto.DateTime.newBuilder().setDateTime(dateTime).build()
    );
  }
}
