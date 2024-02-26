package io.nextsense.android.base.devices.kauai_medical;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class SetRecordingOptionsCommand extends KauaiMedicalFirmwareMessage {

  public SetRecordingOptionsCommand(int id, boolean saveToFile, boolean continuousImpedance, int sampleRate) {
    super(KauaiFirmwareMessageProto.MessageType.SET_RECORDING_SETTINGS, id);

    KauaiFirmwareMessageProto.RecordingOptions.Builder recOptionsBuilder =
        KauaiFirmwareMessageProto.RecordingOptions.newBuilder();
    recOptionsBuilder.setSaveToFile(saveToFile)
        .setContinuousImpedance(continuousImpedance)
        .setSampleRate(sampleRate);

    getBuilder().setRecordingOptions(recOptionsBuilder);
  }
}
