package io.nextsense.android.base;

import android.util.Log;

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
}
