package io.nextsense.android.base.data;

import io.objectbox.annotation.Entity;
import io.objectbox.annotation.Id;

/**
 * Base sample which contains session information and ObjectBox persistence fields.
 */
@Entity
public class BaseSample {
  @Id
  public long id;
  private int sessionId;


  public BaseSample() {}

  public BaseSample(long id, int sessionId) {
    this.id = id;
    this.sessionId = sessionId;
  }

  protected BaseSample(int sessionId) {
    this.sessionId = sessionId;
  }

  public int getSessionId() {
    return sessionId;
  }
}
