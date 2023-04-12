package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import com.google.common.collect.Sets;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.Set;

import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.RotatingFileLogger;

/**
 * Manages the local sessions. The main rules is that only one session can be running at a time.
 */
public class LocalSessionManager {

  // Interface to listen to when the first data is received after a session is started.
  public interface OnFirstDataReceivedListener {
    void onFirstDataReceived();
  }

  // There can be a delay between the time to send a stop command to the hardware device and that
  // device stopping plus the remaining of the in-memory buffer emptying where valid data will be
  // received after a session is stopped.
  public static final Duration ACTIVE_SESSION_EXTRA_TIME = Duration.ofSeconds(30);

  private static final String TAG = LocalSessionManager.class.getSimpleName();

  private final ObjectBoxDatabase objectBoxDatabase;
  private LocalSession activeLocalSession;
  private LocalSession lastActiveSession;
  private Instant lastActiveSessionEnd;
  private final Set<OnFirstDataReceivedListener> onFirstDataReceivedListeners =
      Sets.newConcurrentHashSet();

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

  public synchronized boolean canStartNewSession() {
    // Once it reach the ALL_DATA_RECEIVED status, then another session can be started.
    LocalSession lastLocalSession = getActiveLocalSession().orElse(null);
    if (lastLocalSession == null || !lastLocalSession.isUploadNeeded()) {
      return true;
    }
    lastLocalSession = objectBoxDatabase.getLocalSession(lastLocalSession.id);
    return lastLocalSession.getStatus() != LocalSession.Status.RECORDING &&
        lastLocalSession.getStatus() != LocalSession.Status.FINISHED;
  }

  public synchronized long startLocalSession(
      @Nullable String cloudDataSessionId, @Nullable String userBigTableKey,
      @Nullable String earbudsConfig, boolean uploadNeeded, float eegSampleRate,
      float accelerationSampleRate) {
    if (!canStartNewSession()) {
      RotatingFileLogger.get().logw(TAG, "Trying to start a session, but one is already active.");
      return -1;
    }
    activeLocalSession = LocalSession.create(userBigTableKey, cloudDataSessionId, earbudsConfig,
        uploadNeeded, /*receivedData=*/false, eegSampleRate, accelerationSampleRate, Instant.now());
    return objectBoxDatabase.putLocalSession(activeLocalSession);
  }

  public synchronized void stopLocalSession() {
    if (activeLocalSession == null) {
      RotatingFileLogger.get().logw(TAG, "Trying to stop the active session, but none is active.");
      return;
    }
    objectBoxDatabase.runInTx(() -> {
      // There must be an active session at this point so no need to check.
      Optional<LocalSession> activeLocalSessionOptional = objectBoxDatabase.getActiveSession();
      if (activeLocalSessionOptional.isPresent()) {
        activeLocalSession = activeLocalSessionOptional.get();
      } else {
        RotatingFileLogger.get().logw(TAG,
            "Trying to stop the active session, but none is active in the database.");
        if (activeLocalSession.getStatus() == LocalSession.Status.FINISHED ||
            activeLocalSession.getStatus() == LocalSession.Status.ALL_DATA_RECEIVED ||
            activeLocalSession.getStatus() == LocalSession.Status.UPLOADED ||
            activeLocalSession.getStatus() == LocalSession.Status.COMPLETED) {
          // If not marked as finished, let it be finished to have a consistent DB state. This
          // should not happen though.
          return;
        }
      }
      activeLocalSession.setStatus(LocalSession.Status.FINISHED);
      activeLocalSession.setEndTime(Instant.now());
      objectBoxDatabase.putLocalSession(activeLocalSession);
      RotatingFileLogger.get().logi(TAG, "Local session " + activeLocalSession.id +
          " finished. Cloud data session id: " + activeLocalSession.getCloudDataSessionId() + ".");
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

  public synchronized void notifyFirstDataReceived() {
    if (activeLocalSession != null) {
      activeLocalSession.setReceivedData(true);
      objectBoxDatabase.putLocalSession(activeLocalSession);
      onFirstDataReceivedListeners.forEach(OnFirstDataReceivedListener::onFirstDataReceived);
    }
  }

  public synchronized void addOnFirstDataReceivedListener(OnFirstDataReceivedListener listener) {
    onFirstDataReceivedListeners.add(listener);
    if (activeLocalSession != null && activeLocalSession.isReceivedData()) {
      listener.onFirstDataReceived();
    }
  }

  public synchronized void removeOnFirstDataReceivedListener(OnFirstDataReceivedListener listener) {
    onFirstDataReceivedListeners.remove(listener);
  }
}
