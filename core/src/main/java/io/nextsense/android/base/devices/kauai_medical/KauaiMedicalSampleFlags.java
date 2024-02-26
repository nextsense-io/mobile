package io.nextsense.android.base.devices.kauai_medical;

import androidx.annotation.Nullable;

import com.google.common.collect.ImmutableList;

import java.util.List;

import io.nextsense.android.base.devices.SampleFlags;

/**
 * Kauai per-sample flags.
 */
public class KauaiMedicalSampleFlags implements SampleFlags {

  private static final List<Byte> BIT_MASKS = ImmutableList.of(
      (byte)0x01, (byte)0x02, (byte)0x04, (byte)0x08, (byte)0x10, (byte)0x20, (byte)0x40, (byte)0x80
  );
  private static final int FLAG_INDEX_SYNC = 0;
  private static final int FLAG_INDEX_TRIG_OUT = 1;
  private static final int FLAG_INDEX_TRIG_IN = 2;
  private static final int FLAG_INDEX_TBD_4 = 3;
  private static final int FLAG_INDEX_BUTTON = 4;
  private static final int FLAG_INDEX_HDMI_PRESENT = 5;
  private static final int FLAG_INDEX_TBD_7 = 6;
  private static final int FLAG_INDEX_TBD_8 = 7;

  private final boolean sync;
  private final boolean trigOut;
  private final boolean trigIn;
  private final boolean tbd4;
  private final boolean button;
  private final boolean hdmiPresent;
  private final boolean tbd7;
  private final boolean tbd8;


  private KauaiMedicalSampleFlags(boolean sync, boolean trigOut, boolean trigIn, boolean tbd4,
                                  boolean button, boolean hdmiPresent, boolean tbd7, boolean tbd8) {
    this.sync = sync;
    this.trigOut = trigOut;
    this.trigIn = trigIn;
    this.tbd4 = tbd4;
    this.button = button;
    this.hdmiPresent = hdmiPresent;
    this.tbd7 = tbd7;
    this.tbd8 = tbd8;
  }

  public static KauaiMedicalSampleFlags create(byte flagsByte) {
    boolean sync = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_SYNC)) ==
        BIT_MASKS.get(FLAG_INDEX_SYNC);
    boolean trigOut = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TRIG_OUT)) ==
        BIT_MASKS.get(FLAG_INDEX_TRIG_OUT);
    boolean trigIn = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TRIG_IN)) ==
        BIT_MASKS.get(FLAG_INDEX_TRIG_IN);
    boolean tbd4 = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TBD_4)) ==
        BIT_MASKS.get(FLAG_INDEX_TBD_4);
    boolean button = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_BUTTON)) ==
        BIT_MASKS.get(FLAG_INDEX_BUTTON);
    boolean hdmiPresent = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_HDMI_PRESENT)) ==
        BIT_MASKS.get(FLAG_INDEX_HDMI_PRESENT);
    boolean tbd7 = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TBD_7)) ==
        BIT_MASKS.get(FLAG_INDEX_TBD_7);
    boolean tbd8 = (byte)(flagsByte & BIT_MASKS.get(FLAG_INDEX_TBD_8)) ==
        BIT_MASKS.get(FLAG_INDEX_TBD_8);
    return new KauaiMedicalSampleFlags(sync, trigOut, trigIn, tbd4, button, hdmiPresent, tbd7, tbd8);
  }

  public static KauaiMedicalSampleFlags create(boolean[] flags) {
    boolean sync = flags[FLAG_INDEX_SYNC];
    boolean trigOut = flags[FLAG_INDEX_TRIG_OUT];
    boolean trigIn = flags[FLAG_INDEX_TRIG_IN];
    boolean tbd4 = flags[FLAG_INDEX_TBD_4];
    boolean button = flags[FLAG_INDEX_BUTTON];
    boolean hdmiPresent = flags[FLAG_INDEX_HDMI_PRESENT];
    boolean tbd7 = flags[FLAG_INDEX_TBD_7];
    boolean tbd8 = flags[FLAG_INDEX_TBD_8];
    return new KauaiMedicalSampleFlags(sync, trigOut, trigIn, tbd4, button, hdmiPresent, tbd7, tbd8);
  }

  @Override
  @Nullable
  public Boolean isSync() {
    return sync;
  }

  @Override
  @Nullable
  public Boolean isTrigOut() {
    return trigOut;
  }

  @Override
  @Nullable
  public Boolean isTrigIn() {
    return trigIn;
  }
  public Boolean isTbd4() {
    return tbd4;
  }

  @Override
  @Nullable
  public Boolean isButton() {
    return button;
  }

  @Override
  @Nullable
  public Boolean isHdmiPresent() {
    return hdmiPresent;
  }
  public Boolean isTbd7() {
    return tbd7;
  }

  public Boolean isTbd8() {
    return tbd8;
  }

  @Override
  @Nullable
  public Boolean iszMod() {
    return null;
  }

  @Override
  @Nullable
  public Boolean isMarker() {
    return null;
  }

  public boolean[] getAsBooleanArray() {
    // In order according to their position in the byte.
    return new boolean[]{sync, trigOut, trigIn, tbd4, button, hdmiPresent, tbd7, tbd8};
  }
}
