package io.nextsense.android.base.devices.xenon;

import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.List;

/**
 * Changes the device configuration.
 */
public class SetConfigCommand extends XenonFirmwareCommand {
  private static final byte TRUE = (byte)0x01;
  private static final byte FALSE = (byte)0x00;
  private static final byte CHANNEL_ENABLED_REGISTER = (byte)0x60;
  private static final byte CHANNEL_DISABLED_REGISTER = (byte)0x80;
  private static final byte CHANNEL_IMPEDANCE_REGISTER = (byte)0x68;
  private static final byte MISC_1_DEFAULT = (byte)0x00;
  private static final byte MISC_1_INDEPENDENT_CHANNELS = (byte)0x20;
  private static final byte[] DEFAULT_ADS_1299_REGISTERS = new byte[]{
      // 0xAC,  // REG_ID (Overriden by enabled channels byte)
      (byte)0xf5,  // REG_CONFIG_1
      (byte)0xd0,  // REG_CONFIG_2
      (byte)0xfc,  // REG_CONFIG_3
      (byte)0x01,  // REG_LOFF
      CHANNEL_DISABLED_REGISTER,  // REG_CH1_SET
      CHANNEL_DISABLED_REGISTER,  // REG_CH2_SET
      CHANNEL_DISABLED_REGISTER,  // REG_CH3_SET
      CHANNEL_DISABLED_REGISTER,  // REG_CH4_SET
      CHANNEL_DISABLED_REGISTER,  // REG_CH5_SET
      CHANNEL_DISABLED_REGISTER,  // REG_CH6_SET
      CHANNEL_DISABLED_REGISTER,  // REG_CH7_SET
      CHANNEL_DISABLED_REGISTER,  // REG_CH8_SET
      (byte)0x00,  // REG_BIAS_SENSP
      (byte)0x00,  // REG_BIAS_SENSN
      (byte)0x00,  // REG_LOFF_SENSP
      (byte)0x00,  // REG_LOFF_SENSN
      (byte)0x00,  // REG_LOFF_FLIP
      (byte)0x00,  // REG_LOFF_STATP
      (byte)0x00,  // REG_LOFF_STATN
      (byte)0x0f,  // REG_GPIO
      MISC_1_DEFAULT,  // REG_MISC_1
      (byte)0x00,  // REG_MISC_2
      (byte)0x00   // REG_CONFIG_4
  };
  private static final byte DEFAULT_OPTOSYNC_OUTPUT = TRUE;
  private static final byte DEFAULT_LOG_TO_SDCARD = FALSE;
  private static final List<Byte> CHANNEL_MASKS = Arrays.asList(
      (byte)0x01,
      (byte)0x02,
      (byte)0x04,
      (byte)0x08,
      (byte)0x10,
      (byte)0x20,
      (byte)0x40,
      (byte)0x80
  );
  private static final int CHANNELS_START_OFFSET = 4;
  private static final int MISC_1_OFFSET = 20;

  private final List<Integer> enabledChannels;
  private final boolean impedanceMode;
  private final int impedanceDivider;

  public SetConfigCommand(List<Integer> enabledChannels, boolean impedanceMode,
                          int impedanceDivider) {
    super(XenonMessageType.SET_CONFIG);
    this.enabledChannels = enabledChannels;
    this.impedanceMode = impedanceMode;
    this.impedanceDivider = impedanceDivider;
  }

  private byte boolToByte(boolean boolValue) {
    return boolValue ? TRUE : FALSE;
  }

  private byte getEnabledChannelsByte(List<Integer> enabledChannels) {
    byte enabledChannelsByte = (byte)0x0;
    for (Integer enabledChannel : enabledChannels) {
      enabledChannelsByte = (byte)(enabledChannelsByte | CHANNEL_MASKS.get(enabledChannel - 1));
    }
    return enabledChannelsByte;
  }

  byte[] getASD1299Registers(List<Integer> enabledChannels, boolean impedanceMode) {
    byte[] registers = DEFAULT_ADS_1299_REGISTERS;
    byte channelEnabledRegisterValue = CHANNEL_ENABLED_REGISTER;
    if (impedanceMode) {
      registers[MISC_1_OFFSET] = MISC_1_INDEPENDENT_CHANNELS;
      channelEnabledRegisterValue = CHANNEL_IMPEDANCE_REGISTER;
    }
    for (Integer enabledChannel : enabledChannels) {
      registers[CHANNELS_START_OFFSET + enabledChannel] = channelEnabledRegisterValue;
    }
    return registers;
  }

  @Override
  public byte[] getCommand() {
    ByteBuffer buf = ByteBuffer.allocate(DEFAULT_ADS_1299_REGISTERS.length + 7);
    buf.put(getType().getCode());
    buf.put(getEnabledChannelsByte(enabledChannels));
    buf.put(getASD1299Registers(enabledChannels, impedanceMode));
    buf.put(boolToByte(impedanceMode));
    buf.put((byte)impedanceDivider);
    buf.put(DEFAULT_OPTOSYNC_OUTPUT);
    buf.put(DEFAULT_LOG_TO_SDCARD);
    buf.rewind();
    return buf.array();
  }
}
