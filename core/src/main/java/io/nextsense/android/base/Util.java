package io.nextsense.android.base;

import android.util.Log;

import java.nio.ByteBuffer;

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

  public static int[] getIntValues(byte[] bytes) {
    ByteBuffer byteBuffer = ByteBuffer.allocate(bytes.length);
    byteBuffer.put(bytes);
    byteBuffer.rewind();
    int[] intArray = new int[bytes.length / 4];
    byteBuffer.asIntBuffer().get(intArray);
    return intArray;
  }
}
