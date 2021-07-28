package io.nextsense.android.base.db.objectbox;

import android.content.Context;

import io.nextsense.android.base.db.Database;
import io.objectbox.BoxStore;

/**
 *
 */
public class ObjectBoxDatabase implements Database {

  private BoxStore boxStore;

  @Override
  public void init(Context context) {
    boxStore = MyObjectBox.builder().androidContext(context.getApplicationContext()).build();
  }

  
}
