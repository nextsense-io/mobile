package io.nextsense.android.base.devices;

import androidx.annotation.Nullable;

public interface SampleFlags {
  @Nullable
  Boolean isSync();

  @Nullable
  Boolean isTrigOut();

  @Nullable
  Boolean isTrigIn();

  @Nullable
  Boolean isButton();

  @Nullable
  Boolean isHdmiPresent();

  @Nullable
  Boolean iszMod() ;

  @Nullable
  Boolean isMarker();
}
