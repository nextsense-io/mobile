package io.nextsense.android.base.data;

/**
 * Container for all data entities that need to be saved together.
 */
public class Sample {
    private final EegSample eegSample;
    private final Acceleration acceleration;

    private Sample(EegSample eegSample, Acceleration acceleration) {
        this.eegSample = eegSample;
        this.acceleration = acceleration;
    }

    public static Sample create(EegSample eegSample, Acceleration acceleration) {
        return new Sample(eegSample, acceleration);
    }

    public EegSample getEegSample() {
        return eegSample;
    }

    public Acceleration getAcceleration() {
        return acceleration;
    }
}
