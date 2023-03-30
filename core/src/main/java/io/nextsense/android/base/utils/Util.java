package io.nextsense.android.base.utils;

import java.nio.ByteOrder;

/**
 * Common static utility methods.
 */
public class Util {

  private Util() {}

  public static String padString(String string, int length) {
    String format = "%1$" + length + "s";
    return String.format(format, string).replace(' ', '0');
  }

  public static int bytesToInt24(byte[] buffer, int byteOffset, ByteOrder byteOrder) {
    return byteOrder == ByteOrder.LITTLE_ENDIAN?
        ((buffer[byteOffset] << 16) |  // Java handles the sign-bit
        ((buffer[byteOffset + 1] & 0xFF) << 8) |  // Use unsigned value, ignore the sign-bit
        (buffer[byteOffset + 2] & 0xFF)):
        ((buffer[byteOffset + 2] << 16) |  // Java handles the sign-bit
        ((buffer[byteOffset + 1] & 0xFF) << 8) |  // Use unsigned value, ignore the sign-bit
        (buffer[byteOffset] & 0xFF));
  }

  public static long bytesToLong48(byte[] buffer, int byteOffset, ByteOrder byteOrder) {
    return byteOrder == ByteOrder.LITTLE_ENDIAN?
        (((long)buffer[byteOffset] << 40) |  // Java handles the sign-bit
        (((long)buffer[byteOffset + 1] & 0xFF) << 32) |  // Use unsigned value, ignore the sign-bit
        (((long)buffer[byteOffset + 2] & 0xFF) << 24) |  // Use unsigned value, ignore the sign-bit
        (((long)buffer[byteOffset + 3] & 0xFF) << 16) |  // Use unsigned value, ignore the sign-bit
        (((long)buffer[byteOffset + 4] & 0xFF) << 8) |  // Use unsigned value, ignore the sign-bit
        (buffer[byteOffset + 5] & 0xFF)):
        (((long)buffer[byteOffset + 5] << 40) |  // Java handles the sign-bit
        ((long)(buffer[byteOffset + 4] & 0xFF) << 32) |  // Use unsigned value, ignore the sign-bit
        ((long)(buffer[byteOffset + 3] & 0xFF) << 24) |  // Use unsigned value, ignore the sign-bit
        ((long)(buffer[byteOffset + 2] & 0xFF) << 16) |  // Use unsigned value, ignore the sign-bit
        ((long)(buffer[byteOffset + 1] & 0xFF) << 8) |  // Use unsigned value, ignore the sign-bit
        (buffer[byteOffset] & 0xFF));
  }
}
