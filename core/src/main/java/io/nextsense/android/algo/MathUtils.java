package io.nextsense.android.algo;

public class MathUtils {

  private MathUtils() {}

  public static int biggestPowerOfTwoUnder(int n) {
    return (int) Math.pow(2, Math.floor(Math.log(n) / Math.log(2)));
  }
}
