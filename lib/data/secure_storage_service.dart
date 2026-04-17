import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _walletKey = 'aptos_wallet_data';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Guarda la información de la wallet como JSON
  Future<void> saveWalletData({
    required String mnemonics,
    required String publicAddress,
    required String? privateKey, // Si la manejas (opcional)
  }) async {
    final data = {
      'mnemonics': mnemonics,
      'publicAddress': publicAddress,
      'privateKey': privateKey,
    };
    await _storage.write(key: _walletKey, value: jsonEncode(data));
  }

  // Recupera los datos guardados
  Future<Map<String, dynamic>?> getWalletData() async {
    final String? jsonString = await _storage.read(key: _walletKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  // Elimina los datos (útil para logout o reinicio)
  Future<void> clearWalletData() async {
    await _storage.delete(key: _walletKey);
  }
}
