import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService {
  /// Generates a SHA-256 hash of the PIN
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if a given PIN matches the stored hash
  static bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }
}
