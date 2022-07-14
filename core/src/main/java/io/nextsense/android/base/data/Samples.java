package io.nextsense.android.base.data;

import java.util.ArrayList;
import java.util.List;

/**
 * Contains a collection of Sample.
 */
public class Samples {
    private final List<EegSample> eegSamples = new ArrayList<>();
    private final List<Acceleration> accelerations = new ArrayList<>();

    private Samples() {}

    public static Samples create() {
        return new Samples();
    }

    public void addEegSample(EegSample eegSample) {
        eegSamples.add(eegSample);
    }

    public void addAcceleration(Acceleration acceleration) {
        accelerations.add(acceleration);
    }

    public List<EegSample> getEegSamples() {
        return eegSamples;
    }

    public List<Acceleration> getAccelerations() {
        return accelerations;
    }
}
