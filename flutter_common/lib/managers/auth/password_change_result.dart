enum PasswordChangeResult {
  success,
  invalid_password,
  need_reauthentication,
  connection_error,
  error // Some other errors
}