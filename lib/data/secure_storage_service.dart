import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _walletKey = 'aptos_wallet_data'; // Legacy
  static const String _walletsKey = 'aptos_wallets_data_list';
  static const String _activeWalletKey = 'aptos_active_wallet_address';
  static const String _localeKey = 'app_locale';
  static const String _pinHashKey = 'app_pin_hash';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Recovers the list of all wallets
  Future<List<Map<String, dynamic>>> getWalletsData() async {
    final String? listJson = await _storage.read(key: _walletsKey);
    if (listJson != null) {
      final List<dynamic> list = jsonDecode(listJson);
      return list.cast<Map<String, dynamic>>();
    }

    // Migration from a single wallet (legacy)
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

  // Overwrites the entire list of wallets (useful for deletion)
  Future<void> overwriteWallets(List<Map<String, dynamic>> wallets) async {
    await _storage.write(key: _walletsKey, value: jsonEncode(wallets));
  }

  // Saves wallet info by adding it to the list
  Future<void> addWalletData({
    required String mnemonics,
    required String publicAddress,
    required String? privateKey,
    String? name,
  }) async {
    final wallets = await getWalletsData();

    // Avoid duplicates by address
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

  // Gets the active wallet address
  Future<String?> getActiveWalletAddress() async {
    return await _storage.read(key: _activeWalletKey);
  }

  // Sets the active wallet address
  Future<void> setActiveWalletAddress(String address) async {
    await _storage.write(key: _activeWalletKey, value: address);
  }

  // PIN Hash Management
  Future<String?> getPinHash() async {
    return await _storage.read(key: _pinHashKey);
  }

  Future<void> savePinHash(String hash) async {
    await _storage.write(key: _pinHashKey, value: hash);
  }

  Future<void> deletePinHash() async {
    await _storage.delete(key: _pinHashKey);
  }

  // Deletes all wallets
  Future<void> clearWalletsData() async {
    await _storage.delete(key: _walletsKey);
    await _storage.delete(key: _walletKey);
    await _storage.delete(key: _activeWalletKey);
    await deletePinHash();
  }

  // Locale management
  Future<String?> getLocale() async {
    return await _storage.read(key: _localeKey);
  }

  Future<void> setLocale(String languageCode) async {
    await _storage.write(key: _localeKey, value: languageCode);
  }
}
