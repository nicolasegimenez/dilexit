import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _walletKey = 'aptos_wallet_data'; // Legacy
  static const String _walletsKey = 'aptos_wallets_data_list';
  static const String _activeWalletKey = 'aptos_active_wallet_address';
  static const String _localeKey = 'app_locale';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Recupera la lista de todas las wallets
  Future<List<Map<String, dynamic>>> getWalletsData() async {
    final String? listJson = await _storage.read(key: _walletsKey);
    if (listJson != null) {
      final List<dynamic> list = jsonDecode(listJson);
      return list.cast<Map<String, dynamic>>();
    }
    
    // Migración desde una sola wallet (legacy)
    final String? singleJson = await _storage.read(key: _walletKey);
    if (singleJson != null) {
      final data = jsonDecode(singleJson) as Map<String, dynamic>;
      final list = [data];
      await _storage.write(key: _walletsKey, value: jsonEncode(list));
      await setActiveWalletAddress(data['publicAddress']);
      return list;
    }
    
    return [];
  }

  // Sobrescribe la lista completa de wallets (útil para eliminación)
  Future<void> overwriteWallets(List<Map<String, dynamic>> wallets) async {
    await _storage.write(key: _walletsKey, value: jsonEncode(wallets));
  }

  // Guarda la información de una wallet añadiéndola a la lista
  Future<void> addWalletData({
    required String mnemonics,
    required String publicAddress,
    required String? privateKey,
    String? name,
  }) async {
    final wallets = await getWalletsData();
    
    // Evitar duplicados por dirección
    if (!wallets.any((w) => w['publicAddress'] == publicAddress)) {
      wallets.add({
        'mnemonics': mnemonics,
        'publicAddress': publicAddress,
        'privateKey': privateKey,
        'name': name ?? 'Wallet ${wallets.length + 1}',
      });
      await _storage.write(key: _walletsKey, value: jsonEncode(wallets));
    }
    await setActiveWalletAddress(publicAddress);
  }

  // Obtiene la dirección de la wallet activa
  Future<String?> getActiveWalletAddress() async {
    return await _storage.read(key: _activeWalletKey);
  }

  // Establece la dirección de la wallet activa
  Future<void> setActiveWalletAddress(String address) async {
    await _storage.write(key: _activeWalletKey, value: address);
  }

  // Elimina todas las wallets
  Future<void> clearWalletsData() async {
    await _storage.delete(key: _walletsKey);
    await _storage.delete(key: _walletKey);
    await _storage.delete(key: _activeWalletKey);
  }

  // Locale management
  Future<String?> getLocale() async {
    return await _storage.read(key: _localeKey);
  }

  Future<void> setLocale(String languageCode) async {
    await _storage.write(key: _localeKey, value: languageCode);
  }
}
