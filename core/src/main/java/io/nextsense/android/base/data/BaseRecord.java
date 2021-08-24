package io.nextsense.android.base.data;

import io.objectbox.annotation.Entity;
import io.objectbox.annotation.Id;

/**
 * Base sample which contains session information and ObjectBox persistence fields.
 */
@Entity
public class BaseRecord {
  @Id
  public long id;

  public BaseRecord() {}

  public BaseRecord(long id) {
    this.id = id;
  }
}
