package io.nextsense.android.base.devices.h1;

import java.nio.ByteBuffer;
import java.util.Arrays;

import javax.annotation.concurrent.Immutable;

import io.nextsense.android.base.devices.FirmwareMessageParsingException;

import static java.lang.Math.ceil;

/**
 * H1 Battery information response.
 */
@Immutable
public final class BatteryInfoResponse extends H1FirmwareResponse {

  private static final int EXPECTED_MESSAGE_LENGTH = 3;
  private static final int VOLTAGE_INDEX = 1;
  private static final int VOLTAGE_LENGTH = 2;

  private final int voltage;

  public static BatteryInfoResponse parseFromBytes(byte[] values)
      throws FirmwareMessageParsingException {
    if (values.length == EXPECTED_MESSAGE_LENGTH) {
      ByteBuffer voltageBuffer = ByteBuffer.allocate(VOLTAGE_LENGTH);
      voltageBuffer.put(Arrays.copyOfRange(values, VOLTAGE_INDEX, VOLTAGE_INDEX + VOLTAGE_LENGTH));
      voltageBuffer.rewind();
      int voltage = voltageBuffer.getShort();
      return new BatteryInfoResponse(voltage);
    } else {
      throw new FirmwareMessageParsingException(
          "Expected 3 bytes but got " + values.length + '.');
    }
  }

  private BatteryInfoResponse(int voltage) {
    super(H1MessageType.BATTERY_INFO);
    this.voltage = voltage;
  }

  public int getVoltage() {
    return voltage;
  }

  public int getPercentage() {
    // The relation between the voltage and the percentage might not be linear, but hopefully this
    // approximates it well enough.
    float batteryPercentage = (float)(voltage - H1Device.MIN_BATTERY_VOLTAGE) * 100 /
        (H1Device.MAX_BATTERY_VOLTAGE - H1Device.MIN_BATTERY_VOLTAGE);
    // Use ceil as 0% should not be displayed (the device should have shut down at that point).
    int percentage = (int)ceil(batteryPercentage);
    // In case the reported voltage is out of the typical bounds.
    if (percentage > 100) {
      percentage = 100;
    } else if (percentage < 0) {
      percentage = 0;
    }
    return percentage;
  }
}
