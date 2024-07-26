package io.nextsense.android.base.devices.maui;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class MauiDataParserTest {

  @Test
  public void testConvertToMicroVolts() {
    // ADC max value
    assertEquals(91666.671875, MauiDataParser.convertToMicroVolts(2097151), 0.001);
    // ADC min value
    assertEquals(-91666.671875, MauiDataParser.convertToMicroVolts(2097152), 0.001);
    assertEquals(0, MauiDataParser.convertToMicroVolts(0), 0.001);
    assertEquals(0.0437, MauiDataParser.convertToMicroVolts(1), 0.001);
    assertEquals(0, MauiDataParser.convertToMicroVolts(4194304), 0.001);
    assertEquals(-0.0437, MauiDataParser.convertToMicroVolts(4194303), 0.001);
  }
}
