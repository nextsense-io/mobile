package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import com.google.common.collect.ImmutableList;

import java.time.Instant;
import java.util.List;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.relation.ToOne;

/**
 * IMU Acceleration components.
 * Either the relative or absolute sampling timestamp need to be provided.
 */
@Entity
public class Acceleration extends BaseRecord {

  public enum Channels {
    ACC_X("acc_x"),  // Acceleration X from a device with a single value, usually the box.
    ACC_Y("acc_y"),  // Acceleration Y from a device with a single value, usually the box.
    ACC_Z("acc_z"),  // Acceleration Z from a device with a single value, usually the box.
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
  }
  public static final List<String> CHANNELS = ImmutableList.of("acc_x", "acc_y", "acc_z", "acc_r_x",
      "acc_r_y", "acc_r_z", "acc_l_x", "acc_l_y", "acc_l_z");

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
      long localSessionId, @Nullable Integer x, @Nullable Integer y, @Nullable Integer z,
      @Nullable Integer rightX, @Nullable Integer rightY, @Nullable Integer rightZ,
      @Nullable Integer leftX, @Nullable Integer leftY, @Nullable Integer leftZ,
      Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
      @Nullable Instant absoluteSamplingTimestamp) {
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new Acceleration(localSessionId, x, y, z, rightX, rightY, rightZ, leftX, leftY, leftZ,
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
