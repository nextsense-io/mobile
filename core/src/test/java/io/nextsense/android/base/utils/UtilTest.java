package io.nextsense.android.base.utils;

import java.nio.ByteOrder;
import org.junit.Test;

import static org.junit.Assert.*;

public class UtilTest {

  @Test
  public void bytesToInt24_positiveValue_isCorrect() {
    byte[] int24Bytes = new byte[]{(byte)0b00000001, (byte)0b00000010, (byte)0b00000011};
    assertEquals(66051, Util.bytesToInt24(int24Bytes, 0, ByteOrder.LITTLE_ENDIAN));
  }
}
