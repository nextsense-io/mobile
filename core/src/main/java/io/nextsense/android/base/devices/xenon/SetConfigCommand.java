package io.nextsense.android.base.devices.xenon;

import android.util.Log;

import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.List;

import io.nextsense.android.base.DeviceSettings.ImpedanceMode;
import io.nextsense.android.base.utils.Util;

/**
 * Changes the device configuration.
 */
public class SetConfigCommand extends XenonFirmwareCommand {

  private static final String TAG = SetConfigCommand.class.getSimpleName();

  // Registry values
  private static final byte REG_TRUE = (byte)0x01;
  private static final byte REG_FALSE = (byte)0x00;
  private static final byte REG_SAMPLING_RATE_250 = (byte)0xf6;
  private static final byte REG_SAMPLING_RATE_500 = (byte)0xf5;
  private static final byte REG_CHANNEL_ENABLED_REGISTER = (byte)0x60;
  private static final byte REG_CHANNEL_DISABLED_REGISTER = (byte)0x80;
  private static final byte REG_CHANNEL_IMPEDANCE_REGISTER = (byte)0x68;
  private static final byte REG_MISC_1_DEFAULT = (byte)0x00;
  private static final byte REG_MISC_1_INDEPENDENT_CHANNELS = (byte)0x20;
  // ADS1299 Impedance mode disabled.
  private static final byte REG_LOFF_DEFAULT = (byte)0x01;
  // Select AC mode, FDR/4 freq, 6nA current. COMP_THR is not used.
  private static final byte REG_LOFF_AC_MODE = (byte)0x03;
  // Select DC mode, 6nA current. COMP_THR at 80/20%. These values will need tweaks.
  private static final byte REG_LOFF_DC_MODE = (byte)0xA0;
  // This register can be configured to determine which channels (1-8) are enabled for 1299
  // impedance modes, AC or DC.
  private static final byte REG_LOFF_SENSP_DEFAULT = (byte)0x00;
  private static final byte REG_CONFIG4_DEFAULT = (byte)0x00;
  private static final byte REG_CONFIG4_DC_IMPEDANCE = (byte)0x02;

  // ADS 1299 Register binary values with defaults.
  private static final byte[] DEFAULT_ADS_1299_REGISTERS = new byte[]{
      // 0xAC,  // REG_ID (Overriden by enabled channels byte)
      REG_SAMPLING_RATE_250,  // REG_CONFIG_1
      (byte)0xd0,  // REG_CONFIG_2
      (byte)0xfc,  // REG_CONFIG_3
      REG_LOFF_DEFAULT,  // REG_LOFF
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH1_SET
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH2_SET
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH3_SET
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH4_SET
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH5_SET
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH6_SET
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH7_SET
      REG_CHANNEL_DISABLED_REGISTER,  // REG_CH8_SET
      (byte)0x00,  // REG_BIAS_SENSP
      (byte)0x00,  // REG_BIAS_SENSN
      REG_LOFF_SENSP_DEFAULT,  // REG_LOFF_SENSP
      (byte)0x00,  // REG_LOFF_SENSN
      (byte)0x00,  // REG_LOFF_FLIP
      (byte)0x00,  // REG_LOFF_STATP
      (byte)0x00,  // REG_LOFF_STATN
      (byte)0x0f,  // REG_GPIO
      REG_MISC_1_DEFAULT,  // REG_MISC_1
      (byte)0x00,  // REG_MISC_2
      REG_CONFIG4_DEFAULT   // REG_CONFIG_4
  };
  private static final int REG_LOFF_OFFSET = 3;
  private static final int REG_CHANNELS_START_OFFSET = 4;
  private static final int REG_LOFF_SENSP_OFFSET = 14;
  private static final int REG_MISC_1_OFFSET = 20;
  private static final int REG_CONFIG4_OFFSET = 22;

  private static final byte DEFAULT_OPTOSYNC_OUTPUT = REG_TRUE;
  private static final byte DEFAULT_LOG_TO_SDCARD = REG_FALSE;
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

  private final List<Integer> enabledChannels;
  private final ImpedanceMode impedanceMode;
  private final int impedanceDivider;

  public SetConfigCommand(List<Integer> enabledChannels,  ImpedanceMode impedanceMode,
                          int impedanceDivider) {
    super(XenonMessageType.SET_CONFIG);
    this.enabledChannels = enabledChannels;
    this.impedanceMode = impedanceMode;
    this.impedanceDivider = impedanceDivider;
  }

  private byte boolToByte(boolean boolValue) {
    return boolValue ? REG_TRUE : REG_FALSE;
  }

  private byte getEnabledChannelsByte(List<Integer> enabledChannels) {
    byte enabledChannelsByte = (byte)0x0;
    for (Integer enabledChannel : enabledChannels) {
      enabledChannelsByte = (byte)(enabledChannelsByte | CHANNEL_MASKS.get(enabledChannel - 1));
    }
    return enabledChannelsByte;
  }

  byte[] getASD1299Registers(List<Integer> enabledChannels, ImpedanceMode impedanceMode) {
    byte[] registers = Arrays.copyOf(DEFAULT_ADS_1299_REGISTERS, DEFAULT_ADS_1299_REGISTERS.length);
    byte channelEnabledRegisterValue = REG_CHANNEL_ENABLED_REGISTER;
    if (impedanceMode == ImpedanceMode.ON_EXTERNAL_CURRENT) {
      registers[REG_MISC_1_OFFSET] = REG_MISC_1_INDEPENDENT_CHANNELS;
      channelEnabledRegisterValue = REG_CHANNEL_IMPEDANCE_REGISTER;
    } else {
      registers[REG_MISC_1_OFFSET] = REG_MISC_1_DEFAULT;
    }
    if (impedanceMode == ImpedanceMode.ON_1299_AC) {
      registers[REG_LOFF_OFFSET] = REG_LOFF_AC_MODE;
    } else if (impedanceMode == ImpedanceMode.ON_1299_DC) {
      registers[REG_LOFF_OFFSET] = REG_LOFF_DC_MODE;
      registers[REG_CONFIG4_OFFSET] = REG_CONFIG4_DC_IMPEDANCE;
    }
    if (impedanceMode == ImpedanceMode.ON_1299_AC || impedanceMode == ImpedanceMode.ON_1299_DC) {
      // registers[REG_LOFF_SENSP_OFFSET] = getEnabledChannelsByte(enabledChannels);
      // Turn on probe current for channels 1, 2 and 7.
      registers[REG_LOFF_SENSP_OFFSET] = (byte)0x43;
    }
    for (Integer enabledChannel : enabledChannels) {
      // The first channel is 1, so need to remove 1 to get the correct offset.
      registers[REG_CHANNELS_START_OFFSET + enabledChannel - 1] = channelEnabledRegisterValue;
    }
    if (impedanceMode == ImpedanceMode.ON_1299_AC) {
      // Need to turn on probe current on channel 2.
      registers[REG_CHANNELS_START_OFFSET + 1] = REG_CHANNEL_ENABLED_REGISTER;
    }
    return registers;
  }

  @Override
  public byte[] getCommand() {
    ByteBuffer buf = ByteBuffer.allocate(DEFAULT_ADS_1299_REGISTERS.length + 7);
    buf.put(getType().getCode());
    buf.put(getEnabledChannelsByte(enabledChannels));
    byte[] registers = getASD1299Registers(enabledChannels, impedanceMode);
    buf.put(registers);
    for (int i = 0; i < registers.length; ++i) {
      Util.logd(TAG, "Register at " + i + " " + String.format("0x%08X", registers[i]));
    }
    buf.put(impedanceMode.getCode());
    Util.logd(TAG, "Impedance mode: " + impedanceMode.getCode());
    buf.put((byte)impedanceDivider);
    buf.put(DEFAULT_OPTOSYNC_OUTPUT);
    buf.put(DEFAULT_LOG_TO_SDCARD);
    buf.rewind();
    for (int i = 0; i < buf.array().length; ++i) {
      Util.logd(TAG, "config buffer at " + i + " " + String.format("0x%08X", buf.array()[i]));
    }
    return buf.array();
  }
}
