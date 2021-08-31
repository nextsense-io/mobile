package io.nextsense.android.base.devices.xenon;

import com.google.common.collect.ImmutableList;

import java.util.List;

/**
 * Xenon per-sample flags.
 */
public class SampleFlags {

  private static final List<Byte> BIT_MASKS = ImmutableList.of(
      (byte)0x01, (byte)0x02, (byte)0x04, (byte)0x08, (byte)0x10, (byte)0x20, (byte)0x40, (byte)0x80
  );
  private static final int FLAG_INDEX_SYNC = 0;
  private static final int FLAG_INDEX_TRIG_OUT = 1;
  private static final int FLAG_INDEX_TRIG_IN = 2;
  private static final int FLAG_INDEX_Z_MOD = 3;
  private static final int FLAG_INDEX_MARKER = 4;
  private static final int FLAG_INDEX_TBD_6 = 5;
  private static final int FLAG_INDEX_TBD_7 = 6;
  private static final int FLAG_INDEX_BUTTON = 7;

  private final boolean sync;
  private final boolean trigOut;
  private final boolean trigIn;
  private final boolean zMod;
  private final boolean marker;
  private final boolean tbd6;
  private final boolean tbd7;
  private final boolean button;

  private SampleFlags(boolean sync, boolean trigOut, boolean trigIn, boolean zMod, boolean marker,
                      boolean tbd6, boolean tbd7, boolean button) {
    this.sync = sync;
    this.trigOut = trigOut;
    this.trigIn = trigIn;
    this.zMod = zMod;
    this.marker = marker;
    this.tbd6 = tbd6;
    this.tbd7 = tbd7;
    this.button = button;
  }

  public static SampleFlags create(byte flagsByte) {
      boolean sync = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_SYNC)) ==
          BIT_MASKS.get(FLAG_INDEX_SYNC);
      boolean trigOut = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TRIG_OUT)) ==
          BIT_MASKS.get(FLAG_INDEX_TRIG_OUT);
      boolean trigIn = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TRIG_IN)) ==
          BIT_MASKS.get(FLAG_INDEX_TRIG_IN);
      boolean zMod = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_Z_MOD)) ==
          BIT_MASKS.get(FLAG_INDEX_Z_MOD);
      boolean marker = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_MARKER)) ==
          BIT_MASKS.get(FLAG_INDEX_MARKER);
      boolean tbd6 = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TBD_6)) ==
          BIT_MASKS.get(FLAG_INDEX_TBD_6);
      boolean tbd7 = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TBD_7)) ==
          BIT_MASKS.get(FLAG_INDEX_TBD_7);
      boolean button = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_BUTTON)) ==
          BIT_MASKS.get(FLAG_INDEX_BUTTON);
      return new SampleFlags(sync, trigOut, trigIn, zMod, marker, tbd6, tbd7, button);
  }

  public static SampleFlags create(boolean[] flags) {
    boolean sync = flags[FLAG_INDEX_SYNC];
    boolean trigOut = flags[FLAG_INDEX_TRIG_OUT];
    boolean trigIn = flags[FLAG_INDEX_TRIG_IN];
    boolean zMod = flags[FLAG_INDEX_Z_MOD];
    boolean marker = flags[FLAG_INDEX_MARKER];
    boolean tbd6 = flags[FLAG_INDEX_TBD_6];
    boolean tbd7 = flags[FLAG_INDEX_TBD_7];
    boolean button = flags[FLAG_INDEX_BUTTON];
    return new SampleFlags(sync, trigOut, trigIn, zMod, marker, tbd6, tbd7, button);
  }

  public boolean isSync() {
    return sync;
  }

  public boolean isTrigOut() {
    return trigOut;
  }

  public boolean isTrigIn() {
    return trigIn;
  }

  public boolean iszMod() {
    return zMod;
  }

  public boolean isMarker() {
    return marker;
  }

  public boolean isTbd6() {
    return tbd6;
  }

  public boolean isTbd7() {
    return tbd7;
  }

  public boolean isButton() {
    return button;
  }

  public boolean[] getAsBooleanArray() {
    // In order according to their position in the byte.
    return new boolean[]{sync, trigOut, trigIn, zMod, marker, tbd6, tbd7, button};
  }
}
