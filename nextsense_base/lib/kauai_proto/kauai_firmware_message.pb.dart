//
//  Generated code. Do not modify.
//  source: kauai_firmware_message.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'kauai_firmware_message.pbenum.dart';

export 'kauai_firmware_message.pbenum.dart';

/// Message sent by a mobile app to the Kauai device over BLE connection.
class ClientMessage extends $pb.GeneratedMessage {
  factory ClientMessage({
    MessageType? messageType,
    $core.int? messageId,
    RecordingSettings? recordingSettings,
    DateTime? currentTime,
    RecordingOptions? recordingOptions,
  }) {
    final $result = create();
    if (messageType != null) {
      $result.messageType = messageType;
    }
    if (messageId != null) {
      $result.messageId = messageId;
    }
    if (recordingSettings != null) {
      $result.recordingSettings = recordingSettings;
    }
    if (currentTime != null) {
      $result.currentTime = currentTime;
    }
    if (recordingOptions != null) {
      $result.recordingOptions = recordingOptions;
    }
    return $result;
  }
  ClientMessage._() : super();
  factory ClientMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClientMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClientMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..e<MessageType>(1, _omitFieldNames ? '' : 'messageType', $pb.PbFieldType.OE, defaultOrMaker: MessageType.MESSAGE_TYPE_UNKNOWN, valueOf: MessageType.valueOf, enumValues: MessageType.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'messageId', $pb.PbFieldType.O3)
    ..aOM<RecordingSettings>(3, _omitFieldNames ? '' : 'recordingSettings', subBuilder: RecordingSettings.create)
    ..aOM<DateTime>(4, _omitFieldNames ? '' : 'currentTime', subBuilder: DateTime.create)
    ..aOM<RecordingOptions>(5, _omitFieldNames ? '' : 'recordingOptions', subBuilder: RecordingOptions.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClientMessage clone() => ClientMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClientMessage copyWith(void Function(ClientMessage) updates) => super.copyWith((message) => updates(message as ClientMessage)) as ClientMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientMessage create() => ClientMessage._();
  ClientMessage createEmptyInstance() => create();
  static $pb.PbList<ClientMessage> createRepeated() => $pb.PbList<ClientMessage>();
  @$core.pragma('dart2js:noInline')
  static ClientMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientMessage>(create);
  static ClientMessage? _defaultInstance;

  @$pb.TagNumber(1)
  MessageType get messageType => $_getN(0);
  @$pb.TagNumber(1)
  set messageType(MessageType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get messageId => $_getIZ(1);
  @$pb.TagNumber(2)
  set messageId($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => clearField(2);

  @$pb.TagNumber(3)
  RecordingSettings get recordingSettings => $_getN(2);
  @$pb.TagNumber(3)
  set recordingSettings(RecordingSettings v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasRecordingSettings() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecordingSettings() => clearField(3);
  @$pb.TagNumber(3)
  RecordingSettings ensureRecordingSettings() => $_ensure(2);

  @$pb.TagNumber(4)
  DateTime get currentTime => $_getN(3);
  @$pb.TagNumber(4)
  set currentTime(DateTime v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasCurrentTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearCurrentTime() => clearField(4);
  @$pb.TagNumber(4)
  DateTime ensureCurrentTime() => $_ensure(3);

  @$pb.TagNumber(5)
  RecordingOptions get recordingOptions => $_getN(4);
  @$pb.TagNumber(5)
  set recordingOptions(RecordingOptions v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasRecordingOptions() => $_has(4);
  @$pb.TagNumber(5)
  void clearRecordingOptions() => clearField(5);
  @$pb.TagNumber(5)
  RecordingOptions ensureRecordingOptions() => $_ensure(4);
}

/// Recording (ADS1299) settings
class RecordingSettings extends $pb.GeneratedMessage {
  factory RecordingSettings({
    $core.List<$core.int>? ads1299RegistersConfig,
  }) {
    final $result = create();
    if (ads1299RegistersConfig != null) {
      $result.ads1299RegistersConfig = ads1299RegistersConfig;
    }
    return $result;
  }
  RecordingSettings._() : super();
  factory RecordingSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RecordingSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RecordingSettings', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'ads1299RegistersConfig', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RecordingSettings clone() => RecordingSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RecordingSettings copyWith(void Function(RecordingSettings) updates) => super.copyWith((message) => updates(message as RecordingSettings)) as RecordingSettings;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecordingSettings create() => RecordingSettings._();
  RecordingSettings createEmptyInstance() => create();
  static $pb.PbList<RecordingSettings> createRepeated() => $pb.PbList<RecordingSettings>();
  @$core.pragma('dart2js:noInline')
  static RecordingSettings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingSettings>(create);
  static RecordingSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get ads1299RegistersConfig => $_getN(0);
  @$pb.TagNumber(1)
  set ads1299RegistersConfig($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAds1299RegistersConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearAds1299RegistersConfig() => clearField(1);
}

/// Static information on the hardware and firmware.
class DeviceInfo extends $pb.GeneratedMessage {
  factory DeviceInfo({
    $core.int? deviceRevision,
    $core.int? deviceType,
    $core.int? deviceSerialNumber,
    $core.int? firmwareVersionMajor,
    $core.int? firmwareVersionMinor,
    $core.int? firmwareVersionBuildNumber,
    $core.int? earbudsRevision,
    $core.int? earbudsType,
    $core.int? earbudsSerialNumber,
    $core.int? deviceTimeEpochSeconds,
    $core.Iterable<$core.List<$core.int>>? macAddress,
  }) {
    final $result = create();
    if (deviceRevision != null) {
      $result.deviceRevision = deviceRevision;
    }
    if (deviceType != null) {
      $result.deviceType = deviceType;
    }
    if (deviceSerialNumber != null) {
      $result.deviceSerialNumber = deviceSerialNumber;
    }
    if (firmwareVersionMajor != null) {
      $result.firmwareVersionMajor = firmwareVersionMajor;
    }
    if (firmwareVersionMinor != null) {
      $result.firmwareVersionMinor = firmwareVersionMinor;
    }
    if (firmwareVersionBuildNumber != null) {
      $result.firmwareVersionBuildNumber = firmwareVersionBuildNumber;
    }
    if (earbudsRevision != null) {
      $result.earbudsRevision = earbudsRevision;
    }
    if (earbudsType != null) {
      $result.earbudsType = earbudsType;
    }
    if (earbudsSerialNumber != null) {
      $result.earbudsSerialNumber = earbudsSerialNumber;
    }
    if (deviceTimeEpochSeconds != null) {
      $result.deviceTimeEpochSeconds = deviceTimeEpochSeconds;
    }
    if (macAddress != null) {
      $result.macAddress.addAll(macAddress);
    }
    return $result;
  }
  DeviceInfo._() : super();
  factory DeviceInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeviceInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeviceInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'deviceRevision', $pb.PbFieldType.O3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'deviceType', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'deviceSerialNumber', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'firmwareVersionMajor', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'firmwareVersionMinor', $pb.PbFieldType.O3)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'firmwareVersionBuildNumber', $pb.PbFieldType.O3)
    ..a<$core.int>(7, _omitFieldNames ? '' : 'earbudsRevision', $pb.PbFieldType.O3)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'earbudsType', $pb.PbFieldType.O3)
    ..a<$core.int>(9, _omitFieldNames ? '' : 'earbudsSerialNumber', $pb.PbFieldType.O3)
    ..a<$core.int>(10, _omitFieldNames ? '' : 'deviceTimeEpochSeconds', $pb.PbFieldType.O3)
    ..p<$core.List<$core.int>>(13, _omitFieldNames ? '' : 'macAddress', $pb.PbFieldType.PY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeviceInfo clone() => DeviceInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeviceInfo copyWith(void Function(DeviceInfo) updates) => super.copyWith((message) => updates(message as DeviceInfo)) as DeviceInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceInfo create() => DeviceInfo._();
  DeviceInfo createEmptyInstance() => create();
  static $pb.PbList<DeviceInfo> createRepeated() => $pb.PbList<DeviceInfo>();
  @$core.pragma('dart2js:noInline')
  static DeviceInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeviceInfo>(create);
  static DeviceInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get deviceRevision => $_getIZ(0);
  @$pb.TagNumber(1)
  set deviceRevision($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDeviceRevision() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceRevision() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get deviceType => $_getIZ(1);
  @$pb.TagNumber(2)
  set deviceType($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDeviceType() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceType() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get deviceSerialNumber => $_getIZ(2);
  @$pb.TagNumber(3)
  set deviceSerialNumber($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDeviceSerialNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceSerialNumber() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get firmwareVersionMajor => $_getIZ(3);
  @$pb.TagNumber(4)
  set firmwareVersionMajor($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFirmwareVersionMajor() => $_has(3);
  @$pb.TagNumber(4)
  void clearFirmwareVersionMajor() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get firmwareVersionMinor => $_getIZ(4);
  @$pb.TagNumber(5)
  set firmwareVersionMinor($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasFirmwareVersionMinor() => $_has(4);
  @$pb.TagNumber(5)
  void clearFirmwareVersionMinor() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get firmwareVersionBuildNumber => $_getIZ(5);
  @$pb.TagNumber(6)
  set firmwareVersionBuildNumber($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasFirmwareVersionBuildNumber() => $_has(5);
  @$pb.TagNumber(6)
  void clearFirmwareVersionBuildNumber() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get earbudsRevision => $_getIZ(6);
  @$pb.TagNumber(7)
  set earbudsRevision($core.int v) { $_setSignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasEarbudsRevision() => $_has(6);
  @$pb.TagNumber(7)
  void clearEarbudsRevision() => clearField(7);

  @$pb.TagNumber(8)
  $core.int get earbudsType => $_getIZ(7);
  @$pb.TagNumber(8)
  set earbudsType($core.int v) { $_setSignedInt32(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasEarbudsType() => $_has(7);
  @$pb.TagNumber(8)
  void clearEarbudsType() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get earbudsSerialNumber => $_getIZ(8);
  @$pb.TagNumber(9)
  set earbudsSerialNumber($core.int v) { $_setSignedInt32(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasEarbudsSerialNumber() => $_has(8);
  @$pb.TagNumber(9)
  void clearEarbudsSerialNumber() => clearField(9);

  @$pb.TagNumber(10)
  $core.int get deviceTimeEpochSeconds => $_getIZ(9);
  @$pb.TagNumber(10)
  set deviceTimeEpochSeconds($core.int v) { $_setSignedInt32(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasDeviceTimeEpochSeconds() => $_has(9);
  @$pb.TagNumber(10)
  void clearDeviceTimeEpochSeconds() => clearField(10);

  @$pb.TagNumber(13)
  $core.List<$core.List<$core.int>> get macAddress => $_getList(10);
}

/// Current status of the device.
class DeviceStatus extends $pb.GeneratedMessage {
  factory DeviceStatus({
    $core.int? batteryLevel,
    HostState? state,
  }) {
    final $result = create();
    if (batteryLevel != null) {
      $result.batteryLevel = batteryLevel;
    }
    if (state != null) {
      $result.state = state;
    }
    return $result;
  }
  DeviceStatus._() : super();
  factory DeviceStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeviceStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeviceStatus', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'batteryLevel', $pb.PbFieldType.O3)
    ..e<HostState>(2, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE, defaultOrMaker: HostState.OFF, valueOf: HostState.valueOf, enumValues: HostState.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeviceStatus clone() => DeviceStatus()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeviceStatus copyWith(void Function(DeviceStatus) updates) => super.copyWith((message) => updates(message as DeviceStatus)) as DeviceStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceStatus create() => DeviceStatus._();
  DeviceStatus createEmptyInstance() => create();
  static $pb.PbList<DeviceStatus> createRepeated() => $pb.PbList<DeviceStatus>();
  @$core.pragma('dart2js:noInline')
  static DeviceStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeviceStatus>(create);
  static DeviceStatus? _defaultInstance;

  /// What other status might be good to add here?
  @$pb.TagNumber(1)
  $core.int get batteryLevel => $_getIZ(0);
  @$pb.TagNumber(1)
  set batteryLevel($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBatteryLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearBatteryLevel() => clearField(1);

  @$pb.TagNumber(2)
  HostState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(HostState v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => clearField(2);
}

class RecordingOptions extends $pb.GeneratedMessage {
  factory RecordingOptions({
    $core.bool? saveToFile,
    $core.bool? continuousImpedance,
    $core.int? sampleRate,
  }) {
    final $result = create();
    if (saveToFile != null) {
      $result.saveToFile = saveToFile;
    }
    if (continuousImpedance != null) {
      $result.continuousImpedance = continuousImpedance;
    }
    if (sampleRate != null) {
      $result.sampleRate = sampleRate;
    }
    return $result;
  }
  RecordingOptions._() : super();
  factory RecordingOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RecordingOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RecordingOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'saveToFile')
    ..aOB(2, _omitFieldNames ? '' : 'continuousImpedance')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'sampleRate', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RecordingOptions clone() => RecordingOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RecordingOptions copyWith(void Function(RecordingOptions) updates) => super.copyWith((message) => updates(message as RecordingOptions)) as RecordingOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecordingOptions create() => RecordingOptions._();
  RecordingOptions createEmptyInstance() => create();
  static $pb.PbList<RecordingOptions> createRepeated() => $pb.PbList<RecordingOptions>();
  @$core.pragma('dart2js:noInline')
  static RecordingOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingOptions>(create);
  static RecordingOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get saveToFile => $_getBF(0);
  @$pb.TagNumber(1)
  set saveToFile($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSaveToFile() => $_has(0);
  @$pb.TagNumber(1)
  void clearSaveToFile() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get continuousImpedance => $_getBF(1);
  @$pb.TagNumber(2)
  set continuousImpedance($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContinuousImpedance() => $_has(1);
  @$pb.TagNumber(2)
  void clearContinuousImpedance() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get sampleRate => $_getIZ(2);
  @$pb.TagNumber(3)
  set sampleRate($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSampleRate() => $_has(2);
  @$pb.TagNumber(3)
  void clearSampleRate() => clearField(3);
}

class DateTime extends $pb.GeneratedMessage {
  factory DateTime({
    $core.String? dateTime,
  }) {
    final $result = create();
    if (dateTime != null) {
      $result.dateTime = dateTime;
    }
    return $result;
  }
  DateTime._() : super();
  factory DateTime.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateTime.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DateTime', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'dateTime')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateTime clone() => DateTime()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateTime copyWith(void Function(DateTime) updates) => super.copyWith((message) => updates(message as DateTime)) as DateTime;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DateTime create() => DateTime._();
  DateTime createEmptyInstance() => create();
  static $pb.PbList<DateTime> createRepeated() => $pb.PbList<DateTime>();
  @$core.pragma('dart2js:noInline')
  static DateTime getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateTime>(create);
  static DateTime? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dateTime => $_getSZ(0);
  @$pb.TagNumber(1)
  set dateTime($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDateTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearDateTime() => clearField(1);
}

class SignalData extends $pb.GeneratedMessage {
  factory SignalData({
    $fixnum.Int64? unixTimestamp,
    $core.Iterable<$core.int>? sampleCounter,
    $core.Iterable<$core.int>? eegData,
    $core.Iterable<$core.int>? accelData,
    $core.Iterable<$core.int>? flags,
    $core.Iterable<$core.int>? leadOffPosSignal,
  }) {
    final $result = create();
    if (unixTimestamp != null) {
      $result.unixTimestamp = unixTimestamp;
    }
    if (sampleCounter != null) {
      $result.sampleCounter.addAll(sampleCounter);
    }
    if (eegData != null) {
      $result.eegData.addAll(eegData);
    }
    if (accelData != null) {
      $result.accelData.addAll(accelData);
    }
    if (flags != null) {
      $result.flags.addAll(flags);
    }
    if (leadOffPosSignal != null) {
      $result.leadOffPosSignal.addAll(leadOffPosSignal);
    }
    return $result;
  }
  SignalData._() : super();
  factory SignalData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SignalData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SignalData', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'unixTimestamp')
    ..p<$core.int>(2, _omitFieldNames ? '' : 'sampleCounter', $pb.PbFieldType.P3)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'eegData', $pb.PbFieldType.PS3)
    ..p<$core.int>(4, _omitFieldNames ? '' : 'accelData', $pb.PbFieldType.P3)
    ..p<$core.int>(5, _omitFieldNames ? '' : 'flags', $pb.PbFieldType.P3)
    ..p<$core.int>(6, _omitFieldNames ? '' : 'leadOffPosSignal', $pb.PbFieldType.P3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SignalData clone() => SignalData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SignalData copyWith(void Function(SignalData) updates) => super.copyWith((message) => updates(message as SignalData)) as SignalData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignalData create() => SignalData._();
  SignalData createEmptyInstance() => create();
  static $pb.PbList<SignalData> createRepeated() => $pb.PbList<SignalData>();
  @$core.pragma('dart2js:noInline')
  static SignalData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SignalData>(create);
  static SignalData? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get unixTimestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set unixTimestamp($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUnixTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnixTimestamp() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get sampleCounter => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get eegData => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get accelData => $_getList(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get flags => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$core.int> get leadOffPosSignal => $_getList(5);
}

class SignalDataPacket extends $pb.GeneratedMessage {
  factory SignalDataPacket({
    $core.List<$core.int>? activeChannels,
    $core.Iterable<SignalData>? signalData,
  }) {
    final $result = create();
    if (activeChannels != null) {
      $result.activeChannels = activeChannels;
    }
    if (signalData != null) {
      $result.signalData.addAll(signalData);
    }
    return $result;
  }
  SignalDataPacket._() : super();
  factory SignalDataPacket.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SignalDataPacket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SignalDataPacket', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'activeChannels', $pb.PbFieldType.OY)
    ..pc<SignalData>(2, _omitFieldNames ? '' : 'signalData', $pb.PbFieldType.PM, subBuilder: SignalData.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SignalDataPacket clone() => SignalDataPacket()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SignalDataPacket copyWith(void Function(SignalDataPacket) updates) => super.copyWith((message) => updates(message as SignalDataPacket)) as SignalDataPacket;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SignalDataPacket create() => SignalDataPacket._();
  SignalDataPacket createEmptyInstance() => create();
  static $pb.PbList<SignalDataPacket> createRepeated() => $pb.PbList<SignalDataPacket>();
  @$core.pragma('dart2js:noInline')
  static SignalDataPacket getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SignalDataPacket>(create);
  static SignalDataPacket? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get activeChannels => $_getN(0);
  @$pb.TagNumber(1)
  set activeChannels($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasActiveChannels() => $_has(0);
  @$pb.TagNumber(1)
  void clearActiveChannels() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<SignalData> get signalData => $_getList(1);
}

/// Common fields for a firmware response to a client message.
class Result extends $pb.GeneratedMessage {
  factory Result({
    ErrorType? errorType,
    $core.String? additionalInfo,
  }) {
    final $result = create();
    if (errorType != null) {
      $result.errorType = errorType;
    }
    if (additionalInfo != null) {
      $result.additionalInfo = additionalInfo;
    }
    return $result;
  }
  Result._() : super();
  factory Result.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Result.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Result', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..e<ErrorType>(1, _omitFieldNames ? '' : 'errorType', $pb.PbFieldType.OE, defaultOrMaker: ErrorType.ERROR_NONE, valueOf: ErrorType.valueOf, enumValues: ErrorType.values)
    ..aOS(2, _omitFieldNames ? '' : 'additionalInfo')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Result clone() => Result()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Result copyWith(void Function(Result) updates) => super.copyWith((message) => updates(message as Result)) as Result;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Result create() => Result._();
  Result createEmptyInstance() => create();
  static $pb.PbList<Result> createRepeated() => $pb.PbList<Result>();
  @$core.pragma('dart2js:noInline')
  static Result getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Result>(create);
  static Result? _defaultInstance;

  @$pb.TagNumber(1)
  ErrorType get errorType => $_getN(0);
  @$pb.TagNumber(1)
  set errorType(ErrorType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasErrorType() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrorType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get additionalInfo => $_getSZ(1);
  @$pb.TagNumber(2)
  set additionalInfo($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAdditionalInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearAdditionalInfo() => clearField(2);
}

/// Message sent by the Kauai device to mobile app
class HostMessage extends $pb.GeneratedMessage {
  factory HostMessage({
    MessageType? messageType,
    $core.int? respToMessageId,
    EventType? eventType,
    Result? result,
    DeviceInfo? deviceInfo,
    RecordingSettings? recordingSettings,
    DeviceStatus? deviceStatus,
  }) {
    final $result = create();
    if (messageType != null) {
      $result.messageType = messageType;
    }
    if (respToMessageId != null) {
      $result.respToMessageId = respToMessageId;
    }
    if (eventType != null) {
      $result.eventType = eventType;
    }
    if (result != null) {
      $result.result = result;
    }
    if (deviceInfo != null) {
      $result.deviceInfo = deviceInfo;
    }
    if (recordingSettings != null) {
      $result.recordingSettings = recordingSettings;
    }
    if (deviceStatus != null) {
      $result.deviceStatus = deviceStatus;
    }
    return $result;
  }
  HostMessage._() : super();
  factory HostMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HostMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HostMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'nextsense'), createEmptyInstance: create)
    ..e<MessageType>(1, _omitFieldNames ? '' : 'messageType', $pb.PbFieldType.OE, defaultOrMaker: MessageType.MESSAGE_TYPE_UNKNOWN, valueOf: MessageType.valueOf, enumValues: MessageType.values)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'respToMessageId', $pb.PbFieldType.O3)
    ..e<EventType>(3, _omitFieldNames ? '' : 'eventType', $pb.PbFieldType.OE, defaultOrMaker: EventType.UNKNOWN_EVENT, valueOf: EventType.valueOf, enumValues: EventType.values)
    ..aOM<Result>(4, _omitFieldNames ? '' : 'result', subBuilder: Result.create)
    ..aOM<DeviceInfo>(5, _omitFieldNames ? '' : 'deviceInfo', subBuilder: DeviceInfo.create)
    ..aOM<RecordingSettings>(6, _omitFieldNames ? '' : 'recordingSettings', subBuilder: RecordingSettings.create)
    ..aOM<DeviceStatus>(7, _omitFieldNames ? '' : 'deviceStatus', subBuilder: DeviceStatus.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HostMessage clone() => HostMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HostMessage copyWith(void Function(HostMessage) updates) => super.copyWith((message) => updates(message as HostMessage)) as HostMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HostMessage create() => HostMessage._();
  HostMessage createEmptyInstance() => create();
  static $pb.PbList<HostMessage> createRepeated() => $pb.PbList<HostMessage>();
  @$core.pragma('dart2js:noInline')
  static HostMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HostMessage>(create);
  static HostMessage? _defaultInstance;

  @$pb.TagNumber(1)
  MessageType get messageType => $_getN(0);
  @$pb.TagNumber(1)
  set messageType(MessageType v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessageType() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageType() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get respToMessageId => $_getIZ(1);
  @$pb.TagNumber(2)
  set respToMessageId($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRespToMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRespToMessageId() => clearField(2);

  @$pb.TagNumber(3)
  EventType get eventType => $_getN(2);
  @$pb.TagNumber(3)
  set eventType(EventType v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEventType() => $_has(2);
  @$pb.TagNumber(3)
  void clearEventType() => clearField(3);

  @$pb.TagNumber(4)
  Result get result => $_getN(3);
  @$pb.TagNumber(4)
  set result(Result v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasResult() => $_has(3);
  @$pb.TagNumber(4)
  void clearResult() => clearField(4);
  @$pb.TagNumber(4)
  Result ensureResult() => $_ensure(3);

  @$pb.TagNumber(5)
  DeviceInfo get deviceInfo => $_getN(4);
  @$pb.TagNumber(5)
  set deviceInfo(DeviceInfo v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDeviceInfo() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeviceInfo() => clearField(5);
  @$pb.TagNumber(5)
  DeviceInfo ensureDeviceInfo() => $_ensure(4);

  @$pb.TagNumber(6)
  RecordingSettings get recordingSettings => $_getN(5);
  @$pb.TagNumber(6)
  set recordingSettings(RecordingSettings v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasRecordingSettings() => $_has(5);
  @$pb.TagNumber(6)
  void clearRecordingSettings() => clearField(6);
  @$pb.TagNumber(6)
  RecordingSettings ensureRecordingSettings() => $_ensure(5);

  @$pb.TagNumber(7)
  DeviceStatus get deviceStatus => $_getN(6);
  @$pb.TagNumber(7)
  set deviceStatus(DeviceStatus v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasDeviceStatus() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeviceStatus() => clearField(7);
  @$pb.TagNumber(7)
  DeviceStatus ensureDeviceStatus() => $_ensure(6);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
