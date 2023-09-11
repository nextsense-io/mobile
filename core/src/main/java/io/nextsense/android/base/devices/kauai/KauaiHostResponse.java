package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

// Container for the KauaiHostMessage that corresponds to responses from commands sent to the device.
public class KauaiHostResponse {
  private final KauaiFirmwareMessageProto.HostMessage hostMessage;

  public KauaiHostResponse(KauaiFirmwareMessageProto.HostMessage hostMessage) {
    this.hostMessage = hostMessage;
  }

  public KauaiFirmwareMessageProto.HostMessage getHostMessage() {
    return hostMessage;
  }
}
