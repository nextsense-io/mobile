package io.nextsense.android.base.data;

import android.util.Log;

import androidx.annotation.Nullable;

import java.util.Optional;

import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;

/**
 * Manages the local sessions. The main rules is that only one session can be running at a time.
 */
public class LocalSessionManager {
  private static final String TAG = LocalSessionManager.class.getSimpleName();

  private final ObjectBoxDatabase objectBoxDatabase;
  private LocalSession activeLocalSession;

  private LocalSessionManager(ObjectBoxDatabase objectBoxDatabase) {
    this.objectBoxDatabase = objectBoxDatabase;
  }

  public static LocalSessionManager create(ObjectBoxDatabase objectBoxDatabase) {
    return new LocalSessionManager(objectBoxDatabase);
  }

  public synchronized void init() {
    Optional<LocalSession> activeSession = objectBoxDatabase.getActiveSession();
    activeSession.ifPresent(localSession -> activeLocalSession = localSession);
  }

  public synchronized void stop() {
    if (activeLocalSession != null) {
      stopLocalSession();
    }
  }

  public synchronized long startLocalSession(
      @Nullable String cloudDataSessionId, @Nullable String userBigTableKey,
      @Nullable String earbudsConfig, boolean uploadNeeded, float eegSampleRate,
      float accelerationSampleRate) {
    if (activeLocalSession != null &&
        activeLocalSession.getStatus() == LocalSession.Status.RECORDING) {
      Log.w(TAG, "Trying to start a session, but one is already active.");
      return -1;
    }
    activeLocalSession = LocalSession.create(userBigTableKey, cloudDataSessionId, earbudsConfig,
        uploadNeeded, eegSampleRate, accelerationSampleRate);
    return objectBoxDatabase.putLocalSession(activeLocalSession);
  }

  public synchronized void stopLocalSession() {
    if (activeLocalSession == null) {
      Log.w(TAG, "Trying to stop the active session, but none is active.");
      return;
    }
    objectBoxDatabase.runInTx(() -> {
      // There must be an active session at this point so no need to check.
      activeLocalSession = objectBoxDatabase.getActiveSession().get();
      activeLocalSession.setStatus(LocalSession.Status.FINISHED);
      objectBoxDatabase.putLocalSession(activeLocalSession);
    });
    activeLocalSession = null;
  }

  public synchronized Optional<LocalSession> getActiveLocalSession() {
    return Optional.ofNullable(activeLocalSession);
  }
}
