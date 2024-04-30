//
//  Generated code. Do not modify.
//  source: kauai_firmware_message.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = {
  '1': 'MessageType',
  '2': [
    {'1': 'MESSAGE_TYPE_UNKNOWN', '2': 0},
    {'1': 'GET_DEVICE_INFO', '2': 1},
    {'1': 'GET_DEVICE_STATUS', '2': 2},
    {'1': 'GET_RECORDING_SETTINGS', '2': 3},
    {'1': 'SET_RECORDING_SETTINGS', '2': 4},
    {'1': 'SET_DATE_TIME', '2': 5},
    {'1': 'START_RECORDING', '2': 6},
    {'1': 'STOP_RECORDING', '2': 7},
    {'1': 'NOTIFY_EVENT', '2': 8},
    {'1': 'GET_SYSTEM_LOG', '2': 9},
    {'1': 'OTA_FW_UPDATE', '2': 10},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlVHlwZRIYChRNRVNTQUdFX1RZUEVfVU5LTk9XThAAEhMKD0dFVF9ERVZJQ0VfSU'
    '5GTxABEhUKEUdFVF9ERVZJQ0VfU1RBVFVTEAISGgoWR0VUX1JFQ09SRElOR19TRVRUSU5HUxAD'
    'EhoKFlNFVF9SRUNPUkRJTkdfU0VUVElOR1MQBBIRCg1TRVRfREFURV9USU1FEAUSEwoPU1RBUl'
    'RfUkVDT1JESU5HEAYSEgoOU1RPUF9SRUNPUkRJTkcQBxIQCgxOT1RJRllfRVZFTlQQCBISCg5H'
    'RVRfU1lTVEVNX0xPRxAJEhEKDU9UQV9GV19VUERBVEUQCg==');

@$core.Deprecated('Use hostStateDescriptor instead')
const HostState$json = {
  '1': 'HostState',
  '2': [
    {'1': 'OFF', '2': 0},
    {'1': 'INITIALIZING', '2': 1},
    {'1': 'IDLE', '2': 2},
    {'1': 'ACTIVE_RECORDING', '2': 3},
    {'1': 'LOW_POWER_RECORDING', '2': 4},
    {'1': 'ACTIVE_CHARGING', '2': 5},
    {'1': 'LOW_POWER_CHARGING', '2': 6},
    {'1': 'CONTACT_FIT_CHECK', '2': 7},
    {'1': 'DEVICE_FIRMWARE_UPDATE', '2': 8},
    {'1': 'STANDBY', '2': 9},
    {'1': 'UNKNOWN', '2': 10},
  ],
};

/// Descriptor for `HostState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List hostStateDescriptor = $convert.base64Decode(
    'CglIb3N0U3RhdGUSBwoDT0ZGEAASEAoMSU5JVElBTElaSU5HEAESCAoESURMRRACEhQKEEFDVE'
    'lWRV9SRUNPUkRJTkcQAxIXChNMT1dfUE9XRVJfUkVDT1JESU5HEAQSEwoPQUNUSVZFX0NIQVJH'
    'SU5HEAUSFgoSTE9XX1BPV0VSX0NIQVJHSU5HEAYSFQoRQ09OVEFDVF9GSVRfQ0hFQ0sQBxIaCh'
    'ZERVZJQ0VfRklSTVdBUkVfVVBEQVRFEAgSCwoHU1RBTkRCWRAJEgsKB1VOS05PV04QCg==');

@$core.Deprecated('Use errorTypeDescriptor instead')
const ErrorType$json = {
  '1': 'ErrorType',
  '2': [
    {'1': 'ERROR_NONE', '2': 0},
    {'1': 'ALREADY_RECORDING', '2': 1},
    {'1': 'HDMI_DISCONNECTED', '2': 2},
    {'1': 'STORAGE_FULL', '2': 3},
  ],
};

/// Descriptor for `ErrorType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorTypeDescriptor = $convert.base64Decode(
    'CglFcnJvclR5cGUSDgoKRVJST1JfTk9ORRAAEhUKEUFMUkVBRFlfUkVDT1JESU5HEAESFQoRSE'
    'RNSV9ESVNDT05ORUNURUQQAhIQCgxTVE9SQUdFX0ZVTEwQAw==');

@$core.Deprecated('Use eventTypeDescriptor instead')
const EventType$json = {
  '1': 'EventType',
  '2': [
    {'1': 'UNKNOWN_EVENT', '2': 0},
    {'1': 'RECORDING_STARTED_BY_DEVICE', '2': 1},
    {'1': 'RECORDING_STOPPED_BY_DEVICE', '2': 2},
    {'1': 'RECORDING_STARTED_BY_APP', '2': 3},
    {'1': 'RECORDING_STOPPED_BY_APP', '2': 4},
    {'1': 'ALL_DATA_SENT', '2': 5},
    {'1': 'HDMI_CABLE_CONNECTED', '2': 6},
    {'1': 'HDMI_CABLE_DISCONNECTED', '2': 7},
    {'1': 'USB_CABLE_CONNECTED', '2': 8},
    {'1': 'USB_CABLE_DISCONNECTED', '2': 9},
    {'1': 'MEMORY_STORAGE_FULL', '2': 10},
    {'1': 'GOING_TO_STANDBY', '2': 11},
    {'1': 'POWERING_OFF', '2': 12},
    {'1': 'BATTERY_LOW', '2': 13},
    {'1': 'STATUS_CHANGE', '2': 14},
    {'1': 'SYSTEM_LOG', '2': 15},
  ],
};

/// Descriptor for `EventType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List eventTypeDescriptor = $convert.base64Decode(
    'CglFdmVudFR5cGUSEQoNVU5LTk9XTl9FVkVOVBAAEh8KG1JFQ09SRElOR19TVEFSVEVEX0JZX0'
    'RFVklDRRABEh8KG1JFQ09SRElOR19TVE9QUEVEX0JZX0RFVklDRRACEhwKGFJFQ09SRElOR19T'
    'VEFSVEVEX0JZX0FQUBADEhwKGFJFQ09SRElOR19TVE9QUEVEX0JZX0FQUBAEEhEKDUFMTF9EQV'
    'RBX1NFTlQQBRIYChRIRE1JX0NBQkxFX0NPTk5FQ1RFRBAGEhsKF0hETUlfQ0FCTEVfRElTQ09O'
    'TkVDVEVEEAcSFwoTVVNCX0NBQkxFX0NPTk5FQ1RFRBAIEhoKFlVTQl9DQUJMRV9ESVNDT05ORU'
    'NURUQQCRIXChNNRU1PUllfU1RPUkFHRV9GVUxMEAoSFAoQR09JTkdfVE9fU1RBTkRCWRALEhAK'
    'DFBPV0VSSU5HX09GRhAMEg8KC0JBVFRFUllfTE9XEA0SEQoNU1RBVFVTX0NIQU5HRRAOEg4KCl'
    'NZU1RFTV9MT0cQDw==');

@$core.Deprecated('Use clientMessageDescriptor instead')
const ClientMessage$json = {
  '1': 'ClientMessage',
  '2': [
    {'1': 'message_type', '3': 1, '4': 1, '5': 14, '6': '.nextsense.MessageType', '10': 'messageType'},
    {'1': 'message_id', '3': 2, '4': 1, '5': 5, '10': 'messageId'},
    {'1': 'recording_settings', '3': 3, '4': 1, '5': 11, '6': '.nextsense.RecordingSettings', '10': 'recordingSettings'},
    {'1': 'current_time', '3': 4, '4': 1, '5': 11, '6': '.nextsense.DateTime', '10': 'currentTime'},
    {'1': 'recording_options', '3': 5, '4': 1, '5': 11, '6': '.nextsense.RecordingOptions', '10': 'recordingOptions'},
  ],
};

/// Descriptor for `ClientMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientMessageDescriptor = $convert.base64Decode(
    'Cg1DbGllbnRNZXNzYWdlEjkKDG1lc3NhZ2VfdHlwZRgBIAEoDjIWLm5leHRzZW5zZS5NZXNzYW'
    'dlVHlwZVILbWVzc2FnZVR5cGUSHQoKbWVzc2FnZV9pZBgCIAEoBVIJbWVzc2FnZUlkEksKEnJl'
    'Y29yZGluZ19zZXR0aW5ncxgDIAEoCzIcLm5leHRzZW5zZS5SZWNvcmRpbmdTZXR0aW5nc1IRcm'
    'Vjb3JkaW5nU2V0dGluZ3MSNgoMY3VycmVudF90aW1lGAQgASgLMhMubmV4dHNlbnNlLkRhdGVU'
    'aW1lUgtjdXJyZW50VGltZRJIChFyZWNvcmRpbmdfb3B0aW9ucxgFIAEoCzIbLm5leHRzZW5zZS'
    '5SZWNvcmRpbmdPcHRpb25zUhByZWNvcmRpbmdPcHRpb25z');

@$core.Deprecated('Use recordingSettingsDescriptor instead')
const RecordingSettings$json = {
  '1': 'RecordingSettings',
  '2': [
    {'1': 'ads1299_registers_config', '3': 1, '4': 1, '5': 12, '10': 'ads1299RegistersConfig'},
  ],
};

/// Descriptor for `RecordingSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingSettingsDescriptor = $convert.base64Decode(
    'ChFSZWNvcmRpbmdTZXR0aW5ncxI4ChhhZHMxMjk5X3JlZ2lzdGVyc19jb25maWcYASABKAxSFm'
    'FkczEyOTlSZWdpc3RlcnNDb25maWc=');

@$core.Deprecated('Use deviceInfoDescriptor instead')
const DeviceInfo$json = {
  '1': 'DeviceInfo',
  '2': [
    {'1': 'device_revision', '3': 1, '4': 1, '5': 5, '10': 'deviceRevision'},
    {'1': 'device_type', '3': 2, '4': 1, '5': 5, '10': 'deviceType'},
    {'1': 'device_serial_number', '3': 3, '4': 1, '5': 5, '10': 'deviceSerialNumber'},
    {'1': 'firmware_version_major', '3': 4, '4': 1, '5': 5, '10': 'firmwareVersionMajor'},
    {'1': 'firmware_version_minor', '3': 5, '4': 1, '5': 5, '10': 'firmwareVersionMinor'},
    {'1': 'firmware_version_build_number', '3': 6, '4': 1, '5': 5, '10': 'firmwareVersionBuildNumber'},
    {'1': 'earbuds_revision', '3': 7, '4': 1, '5': 5, '10': 'earbudsRevision'},
    {'1': 'earbuds_type', '3': 8, '4': 1, '5': 5, '10': 'earbudsType'},
    {'1': 'earbuds_serial_number', '3': 9, '4': 1, '5': 5, '10': 'earbudsSerialNumber'},
    {'1': 'device_time_epoch_seconds', '3': 10, '4': 1, '5': 5, '10': 'deviceTimeEpochSeconds'},
    {'1': 'mac_address', '3': 13, '4': 3, '5': 12, '10': 'macAddress'},
  ],
};

/// Descriptor for `DeviceInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceInfoDescriptor = $convert.base64Decode(
    'CgpEZXZpY2VJbmZvEicKD2RldmljZV9yZXZpc2lvbhgBIAEoBVIOZGV2aWNlUmV2aXNpb24SHw'
    'oLZGV2aWNlX3R5cGUYAiABKAVSCmRldmljZVR5cGUSMAoUZGV2aWNlX3NlcmlhbF9udW1iZXIY'
    'AyABKAVSEmRldmljZVNlcmlhbE51bWJlchI0ChZmaXJtd2FyZV92ZXJzaW9uX21ham9yGAQgAS'
    'gFUhRmaXJtd2FyZVZlcnNpb25NYWpvchI0ChZmaXJtd2FyZV92ZXJzaW9uX21pbm9yGAUgASgF'
    'UhRmaXJtd2FyZVZlcnNpb25NaW5vchJBCh1maXJtd2FyZV92ZXJzaW9uX2J1aWxkX251bWJlch'
    'gGIAEoBVIaZmlybXdhcmVWZXJzaW9uQnVpbGROdW1iZXISKQoQZWFyYnVkc19yZXZpc2lvbhgH'
    'IAEoBVIPZWFyYnVkc1JldmlzaW9uEiEKDGVhcmJ1ZHNfdHlwZRgIIAEoBVILZWFyYnVkc1R5cG'
    'USMgoVZWFyYnVkc19zZXJpYWxfbnVtYmVyGAkgASgFUhNlYXJidWRzU2VyaWFsTnVtYmVyEjkK'
    'GWRldmljZV90aW1lX2Vwb2NoX3NlY29uZHMYCiABKAVSFmRldmljZVRpbWVFcG9jaFNlY29uZH'
    'MSHwoLbWFjX2FkZHJlc3MYDSADKAxSCm1hY0FkZHJlc3M=');

@$core.Deprecated('Use deviceStatusDescriptor instead')
const DeviceStatus$json = {
  '1': 'DeviceStatus',
  '2': [
    {'1': 'battery_level', '3': 1, '4': 1, '5': 5, '10': 'batteryLevel'},
    {'1': 'state', '3': 2, '4': 1, '5': 14, '6': '.nextsense.HostState', '10': 'state'},
  ],
};

/// Descriptor for `DeviceStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceStatusDescriptor = $convert.base64Decode(
    'CgxEZXZpY2VTdGF0dXMSIwoNYmF0dGVyeV9sZXZlbBgBIAEoBVIMYmF0dGVyeUxldmVsEioKBX'
    'N0YXRlGAIgASgOMhQubmV4dHNlbnNlLkhvc3RTdGF0ZVIFc3RhdGU=');

@$core.Deprecated('Use recordingOptionsDescriptor instead')
const RecordingOptions$json = {
  '1': 'RecordingOptions',
  '2': [
    {'1': 'save_to_file', '3': 1, '4': 1, '5': 8, '10': 'saveToFile'},
    {'1': 'continuous_impedance', '3': 2, '4': 1, '5': 8, '10': 'continuousImpedance'},
    {'1': 'sample_rate', '3': 3, '4': 1, '5': 5, '10': 'sampleRate'},
  ],
};

/// Descriptor for `RecordingOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingOptionsDescriptor = $convert.base64Decode(
    'ChBSZWNvcmRpbmdPcHRpb25zEiAKDHNhdmVfdG9fZmlsZRgBIAEoCFIKc2F2ZVRvRmlsZRIxCh'
    'Rjb250aW51b3VzX2ltcGVkYW5jZRgCIAEoCFITY29udGludW91c0ltcGVkYW5jZRIfCgtzYW1w'
    'bGVfcmF0ZRgDIAEoBVIKc2FtcGxlUmF0ZQ==');

@$core.Deprecated('Use dateTimeDescriptor instead')
const DateTime$json = {
  '1': 'DateTime',
  '2': [
    {'1': 'date_time', '3': 1, '4': 1, '5': 9, '10': 'dateTime'},
  ],
};

/// Descriptor for `DateTime`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dateTimeDescriptor = $convert.base64Decode(
    'CghEYXRlVGltZRIbCglkYXRlX3RpbWUYASABKAlSCGRhdGVUaW1l');

@$core.Deprecated('Use signalDataDescriptor instead')
const SignalData$json = {
  '1': 'SignalData',
  '2': [
    {'1': 'unix_timestamp', '3': 1, '4': 1, '5': 3, '10': 'unixTimestamp'},
    {'1': 'sample_counter', '3': 2, '4': 3, '5': 5, '10': 'sampleCounter'},
    {'1': 'eeg_data', '3': 3, '4': 3, '5': 17, '10': 'eegData'},
    {'1': 'accel_data', '3': 4, '4': 3, '5': 5, '10': 'accelData'},
    {'1': 'flags', '3': 5, '4': 3, '5': 5, '10': 'flags'},
    {'1': 'lead_off_pos_signal', '3': 6, '4': 3, '5': 5, '10': 'leadOffPosSignal'},
  ],
};

/// Descriptor for `SignalData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalDataDescriptor = $convert.base64Decode(
    'CgpTaWduYWxEYXRhEiUKDnVuaXhfdGltZXN0YW1wGAEgASgDUg11bml4VGltZXN0YW1wEiUKDn'
    'NhbXBsZV9jb3VudGVyGAIgAygFUg1zYW1wbGVDb3VudGVyEhkKCGVlZ19kYXRhGAMgAygRUgdl'
    'ZWdEYXRhEh0KCmFjY2VsX2RhdGEYBCADKAVSCWFjY2VsRGF0YRIUCgVmbGFncxgFIAMoBVIFZm'
    'xhZ3MSLQoTbGVhZF9vZmZfcG9zX3NpZ25hbBgGIAMoBVIQbGVhZE9mZlBvc1NpZ25hbA==');

@$core.Deprecated('Use signalDataPacketDescriptor instead')
const SignalDataPacket$json = {
  '1': 'SignalDataPacket',
  '2': [
    {'1': 'active_channels', '3': 1, '4': 1, '5': 12, '10': 'activeChannels'},
    {'1': 'signal_data', '3': 2, '4': 3, '5': 11, '6': '.nextsense.SignalData', '10': 'signalData'},
  ],
};

/// Descriptor for `SignalDataPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signalDataPacketDescriptor = $convert.base64Decode(
    'ChBTaWduYWxEYXRhUGFja2V0EicKD2FjdGl2ZV9jaGFubmVscxgBIAEoDFIOYWN0aXZlQ2hhbm'
    '5lbHMSNgoLc2lnbmFsX2RhdGEYAiADKAsyFS5uZXh0c2Vuc2UuU2lnbmFsRGF0YVIKc2lnbmFs'
    'RGF0YQ==');

@$core.Deprecated('Use resultDescriptor instead')
const Result$json = {
  '1': 'Result',
  '2': [
    {'1': 'error_type', '3': 1, '4': 1, '5': 14, '6': '.nextsense.ErrorType', '10': 'errorType'},
    {'1': 'additional_info', '3': 2, '4': 1, '5': 9, '10': 'additionalInfo'},
  ],
};

/// Descriptor for `Result`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resultDescriptor = $convert.base64Decode(
    'CgZSZXN1bHQSMwoKZXJyb3JfdHlwZRgBIAEoDjIULm5leHRzZW5zZS5FcnJvclR5cGVSCWVycm'
    '9yVHlwZRInCg9hZGRpdGlvbmFsX2luZm8YAiABKAlSDmFkZGl0aW9uYWxJbmZv');

@$core.Deprecated('Use hostMessageDescriptor instead')
const HostMessage$json = {
  '1': 'HostMessage',
  '2': [
    {'1': 'message_type', '3': 1, '4': 1, '5': 14, '6': '.nextsense.MessageType', '10': 'messageType'},
    {'1': 'resp_to_message_id', '3': 2, '4': 1, '5': 5, '10': 'respToMessageId'},
    {'1': 'event_type', '3': 3, '4': 1, '5': 14, '6': '.nextsense.EventType', '10': 'eventType'},
    {'1': 'result', '3': 4, '4': 1, '5': 11, '6': '.nextsense.Result', '10': 'result'},
    {'1': 'device_info', '3': 5, '4': 1, '5': 11, '6': '.nextsense.DeviceInfo', '10': 'deviceInfo'},
    {'1': 'recording_settings', '3': 6, '4': 1, '5': 11, '6': '.nextsense.RecordingSettings', '10': 'recordingSettings'},
    {'1': 'device_status', '3': 7, '4': 1, '5': 11, '6': '.nextsense.DeviceStatus', '10': 'deviceStatus'},
  ],
};

/// Descriptor for `HostMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hostMessageDescriptor = $convert.base64Decode(
    'CgtIb3N0TWVzc2FnZRI5CgxtZXNzYWdlX3R5cGUYASABKA4yFi5uZXh0c2Vuc2UuTWVzc2FnZV'
    'R5cGVSC21lc3NhZ2VUeXBlEisKEnJlc3BfdG9fbWVzc2FnZV9pZBgCIAEoBVIPcmVzcFRvTWVz'
    'c2FnZUlkEjMKCmV2ZW50X3R5cGUYAyABKA4yFC5uZXh0c2Vuc2UuRXZlbnRUeXBlUglldmVudF'
    'R5cGUSKQoGcmVzdWx0GAQgASgLMhEubmV4dHNlbnNlLlJlc3VsdFIGcmVzdWx0EjYKC2Rldmlj'
    'ZV9pbmZvGAUgASgLMhUubmV4dHNlbnNlLkRldmljZUluZm9SCmRldmljZUluZm8SSwoScmVjb3'
    'JkaW5nX3NldHRpbmdzGAYgASgLMhwubmV4dHNlbnNlLlJlY29yZGluZ1NldHRpbmdzUhFyZWNv'
    'cmRpbmdTZXR0aW5ncxI8Cg1kZXZpY2Vfc3RhdHVzGAcgASgLMhcubmV4dHNlbnNlLkRldmljZV'
    'N0YXR1c1IMZGV2aWNlU3RhdHVz');

