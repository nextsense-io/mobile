package io.nextsense.android.base.utils;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class EvictingArrayTest {

  @Test
  public void AddElements_underMax_notRemoved() {
    EvictingArray<Integer> array = new EvictingArray<>(2, 1);
    array.addValue(1);
    array.addValue(2);
    assertEquals(2, array.getSize());
    assertEquals(1, array.getLastValues(2).get(0).intValue());
    assertEquals(2, array.getLastValues(2).get(1).intValue());
  }

  @Test
  public void AddElements_overMax_notRemovedIfUnderChunk() {
    EvictingArray<Integer> array = new EvictingArray<>(2, 2);
    array.addValue(1);
    array.addValue(2);
    array.addValue(3);
    assertEquals(3, array.getSize());
    assertEquals(1, array.getLastValues(3).get(0).intValue());
    assertEquals(2, array.getLastValues(3).get(1).intValue());
    assertEquals(3, array.getLastValues(3).get(2).intValue());
  }

  @Test
  public void AddElements_overMax_removedIfEqualToChunk() {
    EvictingArray<Integer> array = new EvictingArray<>(2, 2);
    array.addValue(1);
    array.addValue(2);
    array.addValue(3);
    array.addValue(4);
    assertEquals(2, array.getSize());
    assertEquals(3, array.getLastValues(2).get(0).intValue());
    assertEquals(4, array.getLastValues(2).get(1).intValue());
  }

  @Test
  public void create_maxSizeOne_deleteChunkSizeOne() {
    EvictingArray<Integer> array = new EvictingArray<>(1);
    assertEquals(1, array.getDeleteChunkSize());
  }

  @Test
  public void clear_whenNotEmpty_isEmpty() {
    EvictingArray<Integer> array = new EvictingArray<>(2, 1);
    array.addValue(1);
    array.addValue(2);
    array.clear();
    assertEquals(0, array.getSize());
  }
}
