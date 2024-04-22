package io.nextsense.android.algo.signal;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

import java.util.ArrayList;
import java.util.List;

public class BandPowerAnalysisTest {

  public static List<Float> createSinWaveBuffer(double samplingRate, int lengthMillis, double frequency) {
    int samples = (int)((lengthMillis * samplingRate) / 1000);
    List<Float> output = new ArrayList<>(samples);
    double period = samplingRate / frequency;
    for (int i = 0; i < samples; i++) {
      double angle = 2.0 * Math.PI * i / period;
      output.add((float) Math.sin(angle) * 127f);
    }
    return output;
  }

  @Test
  public void testGetAlphaBandPower() {
    List<Float> signal = createSinWaveBuffer(250, 1000, 10);
    int samplingRate = 250;
    double alphaBandPower = BandPowerAnalysis.getBandPower(signal, samplingRate, BandPowerAnalysis.Band.ALPHA);
    double betaBandPower = BandPowerAnalysis.getBandPower(signal, samplingRate, BandPowerAnalysis.Band.BETA);
    assertEquals(5122.71475, alphaBandPower, 0.001);
    assertEquals(560.55061, betaBandPower, 0.001);
  }

  @Test
  public void testGetBetaBandPower() {
    List<Float> signal = createSinWaveBuffer(250, 1000, 20);
    int samplingRate = 250;
    double alphaBandPower = BandPowerAnalysis.getBandPower(signal, samplingRate, BandPowerAnalysis.Band.ALPHA);
    double betaBandPower = BandPowerAnalysis.getBandPower(signal, samplingRate, BandPowerAnalysis.Band.BETA);
    assertEquals(318.59644, alphaBandPower, 0.001);
    assertEquals(2190.10059, betaBandPower, 0.001);
  }
}
