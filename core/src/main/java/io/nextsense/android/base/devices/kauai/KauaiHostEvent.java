package io.nextsense.android.base.devices.kauai;


import io.nextsense.android.base.KauaiFirmwareMessageProto;

// Container for the Kauai HostMessage that corresponds to events sent from the device.
public class KauaiHostEvent {
  private final KauaiFirmwareMessageProto.HostMessage hostMessage;

  public KauaiHostEvent(KauaiFirmwareMessageProto.HostMessage hostMessage) {
    this.hostMessage = hostMessage;
  }

  public KauaiFirmwareMessageProto.HostMessage getHostMessage() {
    return hostMessage;
  }

}
