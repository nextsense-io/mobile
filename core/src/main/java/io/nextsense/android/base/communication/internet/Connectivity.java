package io.nextsense.android.base.communication.internet;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import androidx.annotation.NonNull;
import com.google.common.collect.Sets;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Monitors the Internet connectivity and notify callers if it changes.
 */
public class Connectivity {

  public enum State {
    NO_CONNECTION,
    LIMITED_CONNECTION,
    FULL_CONNECTION
  }

  public interface StateListener {
    void onStateChange(State newState);
  }

  private final Set<StateListener> stateListeners = Sets.newConcurrentHashSet();

  // Determines if there is a sufficient internet connection to upload data to the cloud.
  private final AtomicReference<State> state = new AtomicReference<>(State.NO_CONNECTION);
  private boolean hasConnection = false;
  private boolean isMetered = false;
  private boolean hasWifi = false;

  public static Connectivity create(Context context) {
    return new Connectivity(context);
  }

  private Connectivity(Context context) {
    ConnectivityManager connectivityManager = context.getSystemService(ConnectivityManager.class);
    NetworkRequest networkRequest = new NetworkRequest.Builder()
        .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
        .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
        .build();
    connectivityManager.requestNetwork(networkRequest, networkCallback);
  }

  public State getState() {
    return state.get();
  }

  public void addStateListener(StateListener stateListener) {
    stateListeners.add(stateListener);
    stateListener.onStateChange(state.get());
  }

  public void removeStateListener(StateListener stateListener) {
    stateListeners.remove(stateListener);
  }

  private void updateConnectionState() {
    if (hasConnection) {
      if (hasWifi) {
        state.set(State.FULL_CONNECTION);
      } else if (isMetered) {
        state.set(State.LIMITED_CONNECTION);
      } else {
        state.set(State.FULL_CONNECTION);
      }
    } else {
      state.set(State.NO_CONNECTION);
    }
    for (StateListener stateListener : stateListeners) {
      stateListener.onStateChange(state.get());
    }
  }

  private final ConnectivityManager.NetworkCallback networkCallback =
      new ConnectivityManager.NetworkCallback() {
    @Override
    public void onAvailable(@NonNull Network network) {
      super.onAvailable(network);
      hasConnection = true;
      updateConnectionState();
    }

    @Override
    public void onLost(@NonNull Network network) {
      super.onLost(network);
      hasConnection = false;
      updateConnectionState();
    }

    @Override
    public void onCapabilitiesChanged(
        @NonNull Network network, @NonNull NetworkCapabilities networkCapabilities) {
      super.onCapabilitiesChanged(network, networkCapabilities);
      isMetered = !networkCapabilities.hasCapability(
          NetworkCapabilities.NET_CAPABILITY_NOT_METERED);
      hasWifi = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI);
      updateConnectionState();
    }
  };
}
