enum AuthenticationResult {
  success,
  invalid_user_setup,  // Invalid user configuration in Firestore
  invalid_username_or_password,
  need_reauthentication,
  user_fetch_failed,  // Failed to load user entity
  connection_error,
  expired_link,  // When using a sign-in link
  error  // Some other errors
}