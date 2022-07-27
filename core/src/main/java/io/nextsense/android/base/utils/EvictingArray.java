package io.nextsense.android.base.utils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * ArrayList that is bounded to a maximum number of elements. When new elements are added at the
 * end, elements at the start are removed if it is over the allowed number of elements.
 *
 * This class is backed by a synchronised list so is generally thread-safe.
 *
 * @param <T> The type that is contained in the array.
 */
public class EvictingArray<T> {
  // Maximum size allowed before starting to delete elements. It will keep at least this number of
  // elements in the array.
  private final int maxSize;
  // Removes elements by this size to not do it too often.
  private final int deleteChunkSize;
  private final List<T> values;

  public EvictingArray(int maxSize, int deleteChunkSize) {
    this.maxSize = maxSize;
    this.deleteChunkSize = deleteChunkSize;
    this.values =
        Collections.synchronizedList(new ArrayList<>(maxSize + deleteChunkSize));
  }

  public EvictingArray(int maxSize) {
    this.maxSize = maxSize;
    this.deleteChunkSize = (int) Math.round(Math.ceil(maxSize / 100f));
    this.values = new ArrayList<>(maxSize + deleteChunkSize);
  }

  public int getMaxSize() {
    return maxSize;
  }

  public int getDeleteChunkSize() {
    return deleteChunkSize;
  }

  public int getSize() {
    return values.size();
  }

  public List<T> getValues() {
    return values;
  }

  public void addValue(T value) {
    this.values.add(value);
    deleteIfNeeded();
  }

  public void addValues(List<T> values) {
    this.values.addAll(values);
    deleteIfNeeded();
  }

  public List<T> getLastValues(int numberOfValues) {
    return new ArrayList<>(
        values.subList(Math.max(0, values.size() - numberOfValues), values.size()));
  }

  public void clear() {
    values.clear();
  }

  public void delete() {
    clear();
  }

  private void deleteIfNeeded() {
    if (values.size() >= maxSize + deleteChunkSize) {
      values.subList(0, values.size() - maxSize).clear();
    }
  }
}
