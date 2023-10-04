package io.nextsense.android.base.devices.kauai;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class SetDateTimeCommand extends KauaiFirmwareMessage {

  private static final DateTimeFormatter formatter = DateTimeFormatter
      .ofPattern("yyyy-MM-dd'T'hh:mm:ss").withZone(ZoneId.from(ZoneOffset.UTC));

  public SetDateTimeCommand(int id, Instant dateTime) {
    super(KauaiFirmwareMessageProto.MessageType.SET_DATE_TIME, id);
    getBuilder().setCurrentTime(
        KauaiFirmwareMessageProto.DateTime.newBuilder().setDateTime(
            formatter.format(dateTime)).build()
    );
  }
}
