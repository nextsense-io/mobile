package io.nextsense.android.base;

import android.util.Log;

/**
 * Common static utility methods.
 */
public class Util {

  public static void Logv(String tag, String txt) {
    if (BuildConfig.DEBUG && BuildConfig.BUILD_TYPE.equals("debug")) Log.v(tag, txt);
  }

  public static void Logd(String tag, String txt) {
    if (BuildConfig.DEBUG && BuildConfig.BUILD_TYPE.equals("debug")) Log.d(tag, txt);
  }
}
