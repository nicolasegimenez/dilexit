import 'package:flutter/material.dart';
import 'package:dilexit/data/secure_storage_service.dart';

class LocaleProvider with ChangeNotifier {
  final SecureStorageService _storageService;
  Locale _locale = const Locale('es');

  LocaleProvider(this._storageService) {
    _loadLocale();
  }

  Locale get locale => _locale;

  Future<void> _loadLocale() async {
    final languageCode = await _storageService.getLocale();
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'es'].contains(locale.languageCode)) return;
    _locale = locale;
    await _storageService.setLocale(locale.languageCode);
    notifyListeners();
  }
}
