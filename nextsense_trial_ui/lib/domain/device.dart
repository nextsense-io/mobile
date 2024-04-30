/// Each entry corresponds to a field name in the database instance.
/// If any fields are added here, they need to be added to the Device class in
/// https://github.com/nextsense-io/mobile_backend/lib/models/device.py
enum DeviceKey {
  // Mac Address of the device.
  mac_address,
  type,
  revision,
  firmware_version,
  earbud_type,
  earbud_revision,
  earbud_config,
  current_user_id,
  current_study_id,
  prev_user_ids,
  prev_study_ids
}