package io.nextsense.android.base.utils;

import android.util.Log;

import java.nio.ByteOrder;

import io.nextsense.android.base.BuildConfig;

/**
 * Common static utility methods.
 */
public class Util {

  private Util() {}

  public static void logv(String tag, String txt) {
    if (BuildConfig.DEBUG && BuildConfig.BUILD_TYPE.equals("debug")) Log.v(tag, txt);
  }

  public static void logd(String tag, String txt) {
    if (BuildConfig.DEBUG && BuildConfig.BUILD_TYPE.equals("debug")) Log.d(tag, txt);
  }

  public static String padString(String string, int length) {
    String format = "%1$" + length + "s";
    return String.format(format, string).replace(' ', '0');
  }

  public static int bytesToInt24(byte[] buffer, int byteOffset, ByteOrder byteOrder) {
    return byteOrder == ByteOrder.LITTLE_ENDIAN?
        ((buffer[byteOffset] << 16) // Java handles the sign-bit
            | ((buffer[byteOffset + 1] & 0xFF) << 8) // Use unsigned value, ignore the sign-bit
            | ((buffer[byteOffset + 2] & 0xFF))):
        ((buffer[byteOffset + 2] << 16) // Java handles the sign-bit
            | ((buffer[byteOffset + 1] & 0xFF) << 8) // Use unsigned value, ignore the sign-bit
            | (buffer[byteOffset] & 0xFF));
  }
}
