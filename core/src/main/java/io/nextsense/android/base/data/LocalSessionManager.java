package io.nextsense.android.base.data;

import android.util.Log;
import androidx.annotation.Nullable;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;

/**
 * Manages the local sessions. The main rules is that only one session can be running at a time.
 */
public class LocalSessionManager {
  // There can be a delay between the time to send a stop command to the hardware device and that
  // device stopping plus the remaining of the in-memory buffer emptying where valid data will be
  // received after a session is stopped.
  public static final Duration ACTIVE_SESSION_EXTRA_TIME = Duration.ofSeconds(30);

  private static final String TAG = LocalSessionManager.class.getSimpleName();

  private final ObjectBoxDatabase objectBoxDatabase;
  private LocalSession activeLocalSession;
  private LocalSession lastActiveSession;
  private Instant lastActiveSessionEnd;

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
        uploadNeeded, eegSampleRate, accelerationSampleRate, Instant.now());
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
      activeLocalSession.setEndTime(Instant.now());
      objectBoxDatabase.putLocalSession(activeLocalSession);
      Log.i(TAG, "Local session " + activeLocalSession.getCloudDataSessionId() + " finished.");
    });
    lastActiveSessionEnd = Instant.now();
    lastActiveSession = activeLocalSession;
    activeLocalSession = null;
  }

  public synchronized Optional<LocalSession> getActiveLocalSession() {
    if (activeLocalSession == null && lastActiveSession != null &&
        Instant.now().isBefore(lastActiveSessionEnd.plus(ACTIVE_SESSION_EXTRA_TIME))) {
      return Optional.of(lastActiveSession);
    }
    return Optional.ofNullable(activeLocalSession);
  }
}
