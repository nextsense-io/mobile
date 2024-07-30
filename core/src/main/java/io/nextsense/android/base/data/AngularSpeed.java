package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.relation.ToOne;

/**
 * IMU Angular speed components from the Gyroscope.
 * Either the relative or absolute sampling timestamp need to be provided.
 */
@Entity
public class AngularSpeed extends BaseRecord {

  public enum Channels {
    GYRO_X("gyro_x"),  // Angular speed X from a device with a single value, usually the box.
    GYRO_Y("gyro_y"),  // Angular speed Y from a device with a single value, usually the box.
    GYRO_Z("gyro_z"),  // Angular speed Z from a device with a single value, usually the box.
    GYRO_R_X("gyro_r_x"),  // Angular speed X from the right earbud.
    GYRO_R_Y("gyro_r_y"),  // Angular speed Y from the right earbud.
    GYRO_R_Z("gyro_r_z"),  // Angular speed Z from the right earbud.
    GYRO_L_X("gyro_l_x"),  // Angular speed X from the left earbud.
    GYRO_L_Y("gyro_l_y"),  // Angular speed Y from the left earbud.
    GYRO_L_Z("gyro_l_z");  // Angular speed Z from the left earbud.

    private final String name;

    Channels(String name) {
      this.name = name;
    }

    public String getName() {
      return name;
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
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant receptionTimestamp;
  @Nullable
  private Integer relativeSamplingTimestamp;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  @Nullable
  private Instant absoluteSamplingTimestamp;

  private AngularSpeed(
      long localSessionId, @Nullable Integer x, @Nullable Integer y, @Nullable Integer z,
      @Nullable Integer rightX, @Nullable Integer rightY, @Nullable Integer rightZ,
      @Nullable Integer leftX, @Nullable Integer leftY, @Nullable Integer leftZ,
      Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
      @Nullable Instant absoluteSamplingTimestamp) {
    this.localSession = new ToOne<>(this, AngularSpeed_.localSession);
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

  public static AngularSpeed create(
      long localSessionId, int x, int y, int z, DeviceLocation location, Instant receptionTimestamp,
      @Nullable Integer relativeSamplingTimestamp, @Nullable Instant absoluteSamplingTimestamp) {
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return switch (location) {
      case BOX -> new AngularSpeed(localSessionId, x, y, z, null, null, null, null, null, null,
          receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
      case RIGHT_EARBUD ->
          new AngularSpeed(localSessionId, null, null, null, x, y, z, null, null, null,
              receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
      case LEFT_EARBUD ->
          new AngularSpeed(localSessionId, null, null, null, null, null, null, x, y, z,
              receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
      default -> throw new IllegalArgumentException("Unknown location: " + location);
    };
  }

  public static AngularSpeed create(
      long localSessionId, @Nullable Integer leftX, @Nullable Integer leftY,
      @Nullable Integer leftZ, @Nullable Integer rightX, @Nullable Integer rightY,
      @Nullable Integer rightZ, Instant receptionTimestamp,
      @Nullable Integer relativeSamplingTimestamp, @Nullable Instant absoluteSamplingTimestamp) {
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new AngularSpeed(localSessionId, null, null, null, rightX, rightY, rightZ, leftX, leftY, leftZ,
        receptionTimestamp, relativeSamplingTimestamp, absoluteSamplingTimestamp);
  }

  // Needs to be public for ObjectBox performance.
  @SuppressWarnings("unused")
  public AngularSpeed(
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

  // Needed for ObjectBox.
  @SuppressWarnings("unused")
  public AngularSpeed() {}

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
    } else if (rightX != null) {
      return DeviceLocation.RIGHT_EARBUD;
    } else if (leftX != null) {
      return DeviceLocation.LEFT_EARBUD;
    } else {
      return DeviceLocation.UNKNOWN;
    }
  }

  public Instant getReceptionTimestamp() {
    return receptionTimestamp;
  }

  public @Nullable Integer getRelativeSamplingTimestamp() {
    return relativeSamplingTimestamp;
  }

  public @Nullable Instant getAbsoluteSamplingTimestamp() {
    return absoluteSamplingTimestamp;
  }
}
