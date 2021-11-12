import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypt/crypt.dart';

class UserPasswordAuthManager {

  static const _saltLength = 16;

  static bool isPasswordValid(String password, String hashedPassword) {
    Crypt crypt = Crypt(hashedPassword);
    return crypt.match(password);
  }

  static String generatePasswordHash(String password) {
    Crypt hashedPassword = Crypt.sha512(password,
        salt: _generateSaltAsBase64String(_saltLength));
    return hashedPassword.toString();
  }

  /// Generates a random salt of [length] bytes from a cryptographically secure
  /// random number generator.
  ///
  /// Each element of this list is a byte.
  static List<int> _generateSalt(int length) {
    var buffer = new Uint8List(length);
    var rng = new Random.secure();
    for (var i = 0; i < length; ++i) {
      buffer[i] = rng.nextInt(256);
    }
    return buffer;
  }

  /// Generates a random salt of [length] bytes from a cryptographically secure
  /// random number generator and encodes it to Base64.
  ///
  /// [length] is the number of bytes generated, not the [length] of the base64
  /// encoded string returned. Decoding the base64 encoded string will yield
  /// [length] number of bytes.
  static String _generateSaltAsBase64String(int length) {
    var encoder = new Base64Encoder();
    return encoder.convert(_generateSalt(length));
  }
}