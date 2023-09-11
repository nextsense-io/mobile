package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;
import com.google.protobuf.ByteString;

public class SetRecordingSettingsCommand extends KauaiFirmwareMessage {

  public SetRecordingSettingsCommand(int id, byte[] ads1299RegistersConfig) {
    super(KauaiFirmwareMessageProto.MessageType.SET_RECORDING_SETTINGS, id);
    getBuilder().setRecordingSettings(
        KauaiFirmwareMessageProto.RecordingSettings.newBuilder()
            .setAds1299RegistersConfig(ByteString.copyFrom(ads1299RegistersConfig))
            .build()
    );
  }
}
