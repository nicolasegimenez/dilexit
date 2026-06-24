import 'package:flutter/material.dart';
import 'package:dilexit/data/secure_storage_service.dart';

enum AuthState { loading, noWallet, locked, unlocked }

class AuthProvider with ChangeNotifier {
  final SecureStorageService _storageService;
  AuthState _state = AuthState.loading;

  AuthProvider(this._storageService) {
    checkInitialState();
  }

  AuthState get state => _state;

  Future<void> checkInitialState() async {
    _state = AuthState.loading;
    notifyListeners();

    // ponytail: removed artificial delay YAGNI
    final wallets = await _storageService.getWalletsData();
    final pinHash = await _storageService.getPinHash();

    if (wallets.isEmpty) {
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
    await _storageService.savePinHash(pin);
    _state = AuthState.unlocked;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final storedPin = await _storageService.getPinHash();
    if (storedPin != null && pin == storedPin) {
      _state = AuthState.unlocked;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storageService.clearWalletsData();
    _state = AuthState.noWallet;
    notifyListeners();
  }
}
