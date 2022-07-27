package io.nextsense.android.base.db;

import android.content.Context;

/**
 * Main interface that should be implemented by all databases.
 */
public interface Database {

  void init(Context context);
}
