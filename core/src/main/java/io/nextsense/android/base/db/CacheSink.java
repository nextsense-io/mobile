package io.nextsense.android.base.db;

import android.util.Log;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.time.Instant;

import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.db.memory.MemoryCache;

/**
 * Listens for incoming data and saves it in the in-memory cache.
 */
public class CacheSink {

    private static final String TAG = CacheSink.class.getSimpleName();

    private final MemoryCache memoryCache;

    private CacheSink(MemoryCache memoryCache) {
        this.memoryCache = memoryCache;
    }

    public static CacheSink create(MemoryCache memoryCache) {
        return new CacheSink(memoryCache);
    }

    public void startListening() {
        if (EventBus.getDefault().isRegistered(this)) {
            Log.w(TAG, "Already registered to EventBus!");
            return;
        }
        EventBus.getDefault().register(this);
        Log.i(TAG, "Started listening to EventBus.");
    }

    public void stopListening() {
        EventBus.getDefault().unregister(this);
        Log.i(TAG, "Stopped listening to EventBus.");
    }

    @Subscribe(threadMode = ThreadMode.ASYNC)
    public void onSamples(Samples samples) {
        Instant saveStartTime = Instant.now();
        memoryCache.addChannelData(samples);
        long saveTime = Instant.now().toEpochMilli() - saveStartTime.toEpochMilli();
        if (saveTime > 20) {
            Log.d(TAG, "It took " + saveTime + " to cache xenon data.");
        }
    }
}
