package io.nextsense.android.base.db.objectbox;

import io.objectbox.annotation.Entity;
import io.objectbox.annotation.Id;

@Entity
public class Sample {
  @Id
  public long id;
  public String name;
}