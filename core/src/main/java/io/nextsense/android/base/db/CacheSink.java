package io.nextsense.android.base.db;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.time.Instant;

import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.db.memory.MemoryCache;
import io.nextsense.android.base.utils.RotatingFileLogger;

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
            RotatingFileLogger.get().logw(TAG, "Already registered to EventBus!");
            return;
        }
        EventBus.getDefault().register(this);
        RotatingFileLogger.get().logi(TAG, "Started listening to EventBus.");
    }

    public void stopListening() {
        EventBus.getDefault().unregister(this);
        RotatingFileLogger.get().logi(TAG, "Stopped listening to EventBus.");
    }

    @Subscribe(threadMode = ThreadMode.ASYNC)
    public synchronized void onSamples(Samples samples) {
        Instant saveStartTime = Instant.now();
        memoryCache.addChannelData(samples);
        long saveTime = Instant.now().toEpochMilli() - saveStartTime.toEpochMilli();
        if (saveTime > 20) {
            RotatingFileLogger.get().logd(TAG, "It took " + saveTime + " to cache xenon data.");
        }
    }
}
