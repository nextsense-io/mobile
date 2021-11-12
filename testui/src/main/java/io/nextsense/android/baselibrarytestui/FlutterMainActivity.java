package io.nextsense.android.baselibrarytestui;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;

/**
 * Override to the base flutter activity so that it closes properly.
 */
public class FlutterMainActivity extends FlutterActivity {

  @Override
  public boolean shouldDestroyEngineWithHost() {
    return true;
  }

  public static CachedEngineIntentBuilder withCachedEngine(@NonNull String cachedEngineId) {
    return new CachedEngineIntentBuilder(FlutterMainActivity.class, cachedEngineId);
  }
}
