package io.nextsense.android.base.devices.kauai_medical;


import io.nextsense.android.base.KauaiFirmwareMessageProto;

// Container for the Kauai HostMessage that corresponds to events sent from the device.
public class KauaiMedicalHostEvent {
  private final KauaiFirmwareMessageProto.HostMessage hostMessage;

  public KauaiMedicalHostEvent(KauaiFirmwareMessageProto.HostMessage hostMessage) {
    this.hostMessage = hostMessage;
  }

  public KauaiFirmwareMessageProto.HostMessage getHostMessage() {
    return hostMessage;
  }

}
