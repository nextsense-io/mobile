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

import 'package:protobuf/protobuf.dart' as $pb;

class MessageType extends $pb.ProtobufEnum {
  static const MessageType MESSAGE_TYPE_UNKNOWN = MessageType._(0, _omitEnumNames ? '' : 'MESSAGE_TYPE_UNKNOWN');
  static const MessageType GET_DEVICE_INFO = MessageType._(1, _omitEnumNames ? '' : 'GET_DEVICE_INFO');
  static const MessageType GET_DEVICE_STATUS = MessageType._(2, _omitEnumNames ? '' : 'GET_DEVICE_STATUS');
  static const MessageType GET_RECORDING_SETTINGS = MessageType._(3, _omitEnumNames ? '' : 'GET_RECORDING_SETTINGS');
  static const MessageType SET_RECORDING_SETTINGS = MessageType._(4, _omitEnumNames ? '' : 'SET_RECORDING_SETTINGS');
  static const MessageType SET_DATE_TIME = MessageType._(5, _omitEnumNames ? '' : 'SET_DATE_TIME');
  static const MessageType START_RECORDING = MessageType._(6, _omitEnumNames ? '' : 'START_RECORDING');
  static const MessageType STOP_RECORDING = MessageType._(7, _omitEnumNames ? '' : 'STOP_RECORDING');
  static const MessageType NOTIFY_EVENT = MessageType._(8, _omitEnumNames ? '' : 'NOTIFY_EVENT');
  static const MessageType GET_SYSTEM_LOG = MessageType._(9, _omitEnumNames ? '' : 'GET_SYSTEM_LOG');
  static const MessageType OTA_FW_UPDATE = MessageType._(10, _omitEnumNames ? '' : 'OTA_FW_UPDATE');

  static const $core.List<MessageType> values = <MessageType> [
    MESSAGE_TYPE_UNKNOWN,
    GET_DEVICE_INFO,
    GET_DEVICE_STATUS,
    GET_RECORDING_SETTINGS,
    SET_RECORDING_SETTINGS,
    SET_DATE_TIME,
    START_RECORDING,
    STOP_RECORDING,
    NOTIFY_EVENT,
    GET_SYSTEM_LOG,
    OTA_FW_UPDATE,
  ];

  static final $core.Map<$core.int, MessageType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MessageType? valueOf($core.int value) => _byValue[value];

  const MessageType._($core.int v, $core.String n) : super(v, n);
}

/// Possible states that the host can be in. 'state machine'
class HostState extends $pb.ProtobufEnum {
  static const HostState OFF = HostState._(0, _omitEnumNames ? '' : 'OFF');
  static const HostState INITIALIZING = HostState._(1, _omitEnumNames ? '' : 'INITIALIZING');
  static const HostState IDLE = HostState._(2, _omitEnumNames ? '' : 'IDLE');
  static const HostState ACTIVE_RECORDING = HostState._(3, _omitEnumNames ? '' : 'ACTIVE_RECORDING');
  static const HostState LOW_POWER_RECORDING = HostState._(4, _omitEnumNames ? '' : 'LOW_POWER_RECORDING');
  static const HostState ACTIVE_CHARGING = HostState._(5, _omitEnumNames ? '' : 'ACTIVE_CHARGING');
  static const HostState LOW_POWER_CHARGING = HostState._(6, _omitEnumNames ? '' : 'LOW_POWER_CHARGING');
  static const HostState CONTACT_FIT_CHECK = HostState._(7, _omitEnumNames ? '' : 'CONTACT_FIT_CHECK');
  static const HostState DEVICE_FIRMWARE_UPDATE = HostState._(8, _omitEnumNames ? '' : 'DEVICE_FIRMWARE_UPDATE');
  static const HostState STANDBY = HostState._(9, _omitEnumNames ? '' : 'STANDBY');
  static const HostState UNKNOWN = HostState._(10, _omitEnumNames ? '' : 'UNKNOWN');

  static const $core.List<HostState> values = <HostState> [
    OFF,
    INITIALIZING,
    IDLE,
    ACTIVE_RECORDING,
    LOW_POWER_RECORDING,
    ACTIVE_CHARGING,
    LOW_POWER_CHARGING,
    CONTACT_FIT_CHECK,
    DEVICE_FIRMWARE_UPDATE,
    STANDBY,
    UNKNOWN,
  ];

  static final $core.Map<$core.int, HostState> _byValue = $pb.ProtobufEnum.initByValue(values);
  static HostState? valueOf($core.int value) => _byValue[value];

  const HostState._($core.int v, $core.String n) : super(v, n);
}

/// Error reported by the firmware in response to a client message.
class ErrorType extends $pb.ProtobufEnum {
  static const ErrorType ERROR_NONE = ErrorType._(0, _omitEnumNames ? '' : 'ERROR_NONE');
  static const ErrorType ALREADY_RECORDING = ErrorType._(1, _omitEnumNames ? '' : 'ALREADY_RECORDING');
  static const ErrorType HDMI_DISCONNECTED = ErrorType._(2, _omitEnumNames ? '' : 'HDMI_DISCONNECTED');
  static const ErrorType STORAGE_FULL = ErrorType._(3, _omitEnumNames ? '' : 'STORAGE_FULL');

  static const $core.List<ErrorType> values = <ErrorType> [
    ERROR_NONE,
    ALREADY_RECORDING,
    HDMI_DISCONNECTED,
    STORAGE_FULL,
  ];

  static final $core.Map<$core.int, ErrorType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ErrorType? valueOf($core.int value) => _byValue[value];

  const ErrorType._($core.int v, $core.String n) : super(v, n);
}

/// Type of event that is being reported by the Kauai device.
class EventType extends $pb.ProtobufEnum {
  static const EventType UNKNOWN_EVENT = EventType._(0, _omitEnumNames ? '' : 'UNKNOWN_EVENT');
  static const EventType RECORDING_STARTED_BY_DEVICE = EventType._(1, _omitEnumNames ? '' : 'RECORDING_STARTED_BY_DEVICE');
  static const EventType RECORDING_STOPPED_BY_DEVICE = EventType._(2, _omitEnumNames ? '' : 'RECORDING_STOPPED_BY_DEVICE');
  static const EventType RECORDING_STARTED_BY_APP = EventType._(3, _omitEnumNames ? '' : 'RECORDING_STARTED_BY_APP');
  static const EventType RECORDING_STOPPED_BY_APP = EventType._(4, _omitEnumNames ? '' : 'RECORDING_STOPPED_BY_APP');
  static const EventType ALL_DATA_SENT = EventType._(5, _omitEnumNames ? '' : 'ALL_DATA_SENT');
  static const EventType HDMI_CABLE_CONNECTED = EventType._(6, _omitEnumNames ? '' : 'HDMI_CABLE_CONNECTED');
  static const EventType HDMI_CABLE_DISCONNECTED = EventType._(7, _omitEnumNames ? '' : 'HDMI_CABLE_DISCONNECTED');
  static const EventType USB_CABLE_CONNECTED = EventType._(8, _omitEnumNames ? '' : 'USB_CABLE_CONNECTED');
  static const EventType USB_CABLE_DISCONNECTED = EventType._(9, _omitEnumNames ? '' : 'USB_CABLE_DISCONNECTED');
  static const EventType MEMORY_STORAGE_FULL = EventType._(10, _omitEnumNames ? '' : 'MEMORY_STORAGE_FULL');
  static const EventType GOING_TO_STANDBY = EventType._(11, _omitEnumNames ? '' : 'GOING_TO_STANDBY');
  static const EventType POWERING_OFF = EventType._(12, _omitEnumNames ? '' : 'POWERING_OFF');
  static const EventType BATTERY_LOW = EventType._(13, _omitEnumNames ? '' : 'BATTERY_LOW');
  static const EventType STATUS_CHANGE = EventType._(14, _omitEnumNames ? '' : 'STATUS_CHANGE');
  static const EventType SYSTEM_LOG = EventType._(15, _omitEnumNames ? '' : 'SYSTEM_LOG');

  static const $core.List<EventType> values = <EventType> [
    UNKNOWN_EVENT,
    RECORDING_STARTED_BY_DEVICE,
    RECORDING_STOPPED_BY_DEVICE,
    RECORDING_STARTED_BY_APP,
    RECORDING_STOPPED_BY_APP,
    ALL_DATA_SENT,
    HDMI_CABLE_CONNECTED,
    HDMI_CABLE_DISCONNECTED,
    USB_CABLE_CONNECTED,
    USB_CABLE_DISCONNECTED,
    MEMORY_STORAGE_FULL,
    GOING_TO_STANDBY,
    POWERING_OFF,
    BATTERY_LOW,
    STATUS_CHANGE,
    SYSTEM_LOG,
  ];

  static final $core.Map<$core.int, EventType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EventType? valueOf($core.int value) => _byValue[value];

  const EventType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
