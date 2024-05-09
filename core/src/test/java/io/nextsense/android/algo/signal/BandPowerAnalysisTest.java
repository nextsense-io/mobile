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
    List<Float> signal = createSinWaveBuffer(250, 33000, 10);
    int samplingRate = 250;
    double alphaBandPower = BandPowerAnalysis.getBandPower(
        signal, samplingRate, BandPowerAnalysis.Band.ALPHA, /*powerLineFrequency=*/null);
    double betaBandPower = BandPowerAnalysis.getBandPower(
        signal, samplingRate, BandPowerAnalysis.Band.BETA, /*powerLineFrequency=*/null);
    assertEquals(2.091572962347404E7, alphaBandPower, 0.001);
    assertEquals(5364.404884013254, betaBandPower, 0.001);
  }

  @Test
  public void testGetBetaBandPower() {
    List<Float> signal = createSinWaveBuffer(250, 33000, 20);
    int samplingRate = 250;
    double alphaBandPower = BandPowerAnalysis.getBandPower(
        signal, samplingRate, BandPowerAnalysis.Band.ALPHA, /*powerLineFrequency=*/null);
    double betaBandPower = BandPowerAnalysis.getBandPower(
        signal, samplingRate, BandPowerAnalysis.Band.BETA, /*powerLineFrequency=*/null);
    assertEquals(1647.9509418388461, alphaBandPower, 0.001);
    assertEquals(5502878.764851844, betaBandPower, 0.001);
  }

  @Test
  public void testRemoveLineNoise() {
    List<Float> signal = createSinWaveBuffer(250, 33000, 60);
    int samplingRate = 250;
    double powerLineBandPower = BandPowerAnalysis.getBandPower(
        signal, samplingRate, 59, 61, /*powerLineFrequency=*/null);
    double noPowerLineBandPower = BandPowerAnalysis.getBandPower(
        signal, samplingRate, 59, 61, /*powerLineFrequency=*/60.0);
    assertEquals(3940519.9467751756, powerLineBandPower, 0.001);
    assertEquals(1260.957333658562, noPowerLineBandPower, 0.001);
  }
}
