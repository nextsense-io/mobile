package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import com.google.common.collect.ImmutableList;

import java.time.Instant;
import java.util.List;
import java.util.Map;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.annotation.Index;
import io.objectbox.relation.ToOne;

/**
 * IMU Acceleration components.
 * Either the relative or absolute sampling timestamp need to be provided.
 */
@Entity
public class Acceleration extends BaseRecord implements TimestampedDataSample {

  public enum Channels {
    ACC_X("x"),  // Acceleration X from a device with a single value, usually the box.
    ACC_Y("y"),  // Acceleration Y from a device with a single value, usually the box.
    ACC_Z("z"),  // Acceleration Z from a device with a single value, usually the box.
    ACC_R_X("acc_r_x"),  // Acceleration X from the right earbud.
    ACC_R_Y("acc_r_y"),  // Acceleration Y from the right earbud.
    ACC_R_Z("acc_r_z"),  // Acceleration Z from the right earbud.
    ACC_L_X("acc_l_x"),  // Acceleration X from the left earbud.
    ACC_L_Y("acc_l_y"),  // Acceleration Y from the left earbud.
    ACC_L_Z("acc_l_z");  // Acceleration Z from the left earbud.

    private final String name;

    Channels(String name) {
      this.name = name;
    }

    public String getName() {
      return name;
    }

    public static List<Channels> getForDeviceLocation(DeviceLocation location) {
      return switch (location) {
        case BOX, UNKNOWN -> ImmutableList.of(ACC_X, ACC_Y, ACC_Z);
        case RIGHT_EARBUD -> ImmutableList.of(ACC_R_X, ACC_R_Y, ACC_R_Z);
        case LEFT_EARBUD -> ImmutableList.of(ACC_L_X, ACC_L_Y, ACC_L_Z);
        case BOTH_EARBUDS -> ImmutableList.of(ACC_R_X, ACC_R_Y, ACC_R_Z, ACC_L_X, ACC_L_Y, ACC_L_Z);
        default -> throw new IllegalArgumentException("Unknown location: " + location);
      };
    }
  }

  public ToOne<LocalSession> localSession;

  @Nullable private Integer x;
  @Nullable private Integer y;
  @Nullable private Integer z;
  @Nullable private Integer rightX;
  @Nullable private Integer rightY;
  @Nullable private Integer rightZ;
  @Nullable private Integer leftX;
  @Nullable private Integer leftY;
  @Nullable private Integer leftZ;
  // When the Android application received the packet from the device.
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant receptionTimestamp;
  @Nullable
  @Index
  private Integer relativeSamplingTimestamp;
  // When the sample was collected on the device.
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  @Index
  @Nullable
  private Instant absoluteSamplingTimestamp;

  private Acceleration(
      long localSessionId, @Nullable Integer x, @Nullable Integer y, @Nullable Integer z,
      @Nullable Integer rightX, @Nullable Integer rightY, @Nullable Integer rightZ,
      @Nullable Integer leftX, @Nullable Integer leftY, @Nullable Integer leftZ,
      Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
      @Nullable Instant absoluteSamplingTimestamp) {
    this.localSession = new ToOne<>(this, Acceleration_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.x = x;
    this.y = y;
    this.z = z;
    this.rightX = rightX;
    this.rightY = rightY;
    this.rightZ = rightZ;
    this.leftX = leftX;
    this.leftY = leftY;
    this.leftZ = leftZ;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
  }

  public static Acceleration create(
      long localSessionId, int x, int y, int z, DeviceLocation location, Instant receptionTimestamp,
      @Nullable Integer relativeSamplingTimestamp, @Nullable Instant absoluteSamplingTimestamp) {
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return switch (location) {
      case BOX -> new Acceleration(localSessionId, x, y, z, null, null, null, null, null, null,
          receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
      case RIGHT_EARBUD ->
          new Acceleration(localSessionId, null, null, null, x, y, z, null, null, null,
              receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
      case LEFT_EARBUD ->
          new Acceleration(localSessionId, null, null, null, null, null, null, x, y, z,
              receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
      default -> throw new IllegalArgumentException("Unknown location: " + location);
    };
  }

  public static Acceleration create(
      long localSessionId, @Nullable Integer leftX, @Nullable Integer leftY,
      @Nullable Integer leftZ, @Nullable Integer rightX, @Nullable Integer rightY,
      @Nullable Integer rightZ, Instant receptionTimestamp,
      @Nullable Integer relativeSamplingTimestamp, @Nullable Instant absoluteSamplingTimestamp) {
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new Acceleration(localSessionId, null, null, null, rightX, rightY, rightZ, leftX, leftY, leftZ,
        receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
  }

  // Needs to be public for ObjectBox performance.
  public Acceleration(
      long id, long localSessionId, @Nullable Integer x, @Nullable Integer y, @Nullable Integer z,
      @Nullable Integer rightX, @Nullable Integer rightY, @Nullable Integer rightZ,
      @Nullable Integer leftX, @Nullable Integer leftY, @Nullable Integer leftZ,
      Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
      @Nullable Instant absoluteSamplingTimestamp) {
    super(id);
    this.localSession = new ToOne<>(this, Acceleration_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.x = x;
    this.y = y;
    this.z = z;
    this.rightX = rightX;
    this.rightY = rightY;
    this.rightZ = rightZ;
    this.leftX = leftX;
    this.leftY = leftY;
    this.leftZ = leftZ;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
  }

  public Acceleration() {}

  public LocalSession getLocalSession() {
    return localSession.getTarget();
  }

  public @Nullable Integer getX() {
    return x;
  }

  public @Nullable Integer getY() {
    return y;
  }

  public @Nullable Integer getZ() {
    return z;
  }

  public @Nullable Integer getRightX() {
    return rightX;
  }

  public @Nullable Integer getRightY() {
    return rightY;
  }

  public @Nullable Integer getRightZ() {
    return rightZ;
  }

  public @Nullable Integer getLeftX() {
    return leftX;
  }

  public @Nullable Integer getLeftY() {
    return leftY;
  }

  public @Nullable Integer getLeftZ() {
    return leftZ;
  }

  public DeviceLocation getDeviceLocation() {
    if (x != null) {
      return DeviceLocation.BOX;
    } else if (rightX != null && leftX != null) {
      return DeviceLocation.BOTH_EARBUDS;
    } else if (rightX != null) {
      return DeviceLocation.RIGHT_EARBUD;
    } else if (leftX != null) {
      return DeviceLocation.LEFT_EARBUD;
    } else {
      return DeviceLocation.UNKNOWN;
    }
  }

  public Map<Channels, Integer> getChannels() {
    Map<Channels, Integer> channels = Map.of();
    switch (getDeviceLocation()) {
      case BOX, UNKNOWN -> channels = Map.of(
          Channels.ACC_X, x,
          Channels.ACC_Y, y,
          Channels.ACC_Z, z);
      case RIGHT_EARBUD -> channels = Map.of(
          Channels.ACC_R_X, rightX,
          Channels.ACC_R_Y, rightY,
          Channels.ACC_R_Z, rightZ);
      case LEFT_EARBUD -> channels = Map.of(
          Channels.ACC_L_X, leftX,
          Channels.ACC_L_Y, leftY,
          Channels.ACC_L_Z, leftZ);
      case BOTH_EARBUDS -> channels = Map.of(
          Channels.ACC_R_X, rightX,
          Channels.ACC_R_Y, rightY,
          Channels.ACC_R_Z, rightZ,
          Channels.ACC_L_X, leftX,
          Channels.ACC_L_Y, leftY,
          Channels.ACC_L_Z, leftZ);
    }
    return channels;
  }

  @Override
  public Instant getReceptionTimestamp() {
    return receptionTimestamp;
  }

  @Override
  public @Nullable Integer getRelativeSamplingTimestamp() {
    return relativeSamplingTimestamp;
  }

  @Override
  public @Nullable Instant getAbsoluteSamplingTimestamp() {
    return absoluteSamplingTimestamp;
  }
}
