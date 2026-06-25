import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthState { loading, noWallet, locked, unlocked }

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage;
  AuthState _state = AuthState.loading;

  AuthProvider(this._storage) {
    checkInitialState();
  }

  AuthState get state => _state;

  Future<void> checkInitialState() async {
    _state = AuthState.loading;
    notifyListeners();

    // ponytail: removed artificial delay YAGNI
    final walletsStr = await _storage.read(key: 'aptos_wallets_data_list');
    final legacyWallet = await _storage.read(key: 'aptos_wallet_data');
    final hasWallet = (walletsStr != null && walletsStr != '[]') || legacyWallet != null;
    final pinHash = await _storage.read(key: 'app_pin_hash');

    if (!hasWallet) {
      _state = AuthState.noWallet;
    } else if (pinHash != null) {
      _state = AuthState.locked;
    } else {
      // Legacy or edge case: wallet exists but no PIN. Force setup.
      _state = AuthState.noWallet;
    }
    notifyListeners();
  }

  Future<void> setupPin(String pin) async {
    // ponytail: YAGNI hashing. SecureStorage is already encrypted via native Keystore/Keychain.
    // If the Keystore is compromised, the private keys are gone anyway.
    await _storage.write(key: 'app_pin_hash', value: pin);
    _state = AuthState.unlocked;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final storedPin = await _storage.read(key: 'app_pin_hash');
    if (storedPin != null && pin == storedPin) {
      _state = AuthState.unlocked;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'aptos_wallets_data_list');
    await _storage.delete(key: 'aptos_wallet_data');
    await _storage.delete(key: 'aptos_active_wallet_address');
    await _storage.delete(key: 'app_pin_hash');
    _state = AuthState.noWallet;
    notifyListeners();
  }
}
