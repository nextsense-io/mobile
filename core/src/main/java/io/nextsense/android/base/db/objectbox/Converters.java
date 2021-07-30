package io.nextsense.android.base.db.objectbox;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.time.Instant;

import io.objectbox.converter.PropertyConverter;

/**
 * Common converters for entity classes.
 */
public class Converters {

  public static class InstantConverter implements PropertyConverter<Instant, Long> {
    @Override
    public Instant convertToEntityProperty(Long databaseValue) {
      if (databaseValue == null) {
        return null;
      }
      return Instant.ofEpochMilli(databaseValue);
    }

    @Override
    public Long convertToDatabaseValue(Instant entityProperty) {
      return entityProperty == null ? null : entityProperty.toEpochMilli();
    }
  }

  public static class SerializableConverter implements PropertyConverter<Serializable, byte[]> {
    @Override
    public Serializable convertToEntityProperty(byte[] databaseValue) {
      if (databaseValue == null) {
        return null;
      }
      ObjectInputStream objectInputStream;
      try {
        objectInputStream = new ObjectInputStream(new ByteArrayInputStream(databaseValue));
        Object object = objectInputStream.readObject();
        objectInputStream.close();
        return (Serializable)object;
      } catch (IOException | ClassNotFoundException e) {
        return null;
      }
    }

    @Override
    public byte[] convertToDatabaseValue(Serializable entityProperty) {
      if (entityProperty == null) {
        return new byte[]{};
      }
      ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
      ObjectOutputStream objectOutputStream;
      try {
        objectOutputStream = new ObjectOutputStream(byteArrayOutputStream);
        objectOutputStream.writeObject(entityProperty);
        objectOutputStream.close();
      } catch (IOException e) {
        return new byte[]{};
      }
      return byteArrayOutputStream.toByteArray();
    }
  }

  private Converters() {}
}
