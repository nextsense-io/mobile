package io.nextsense.android.base.devices.kauai_medical;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

// Container for the KauaiHostMessage that corresponds to responses from commands sent to the device.
public class KauaiMedicalHostResponse {
  private final KauaiFirmwareMessageProto.HostMessage hostMessage;

  public KauaiMedicalHostResponse(KauaiFirmwareMessageProto.HostMessage hostMessage) {
    this.hostMessage = hostMessage;
  }

  public KauaiFirmwareMessageProto.HostMessage getHostMessage() {
    return hostMessage;
  }
}
