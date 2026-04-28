import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Dilexit Wallet',
      'send': 'Send',
      'receive': 'Receive',
      'history': 'History',
      'explore': 'Explore',
      'settings': 'Settings',
      'wallet': 'Wallet',
      'available_balance': 'Available Balance',
      'send_apt': 'Send APT',
      'destination_address': 'Destination Address',
      'amount': 'Amount',
      'confirm_send': 'CONFIRM SEND',
      'processing': 'PROCESSING...',
      'success_send': 'Transaction sent successfully!',
      'error': 'Error',
      'wallets': 'Wallets',
      'main_account': 'Main Account',
      'saved_wallet': 'Saved Wallet',
      'change_wallet': 'Change Wallets',
      'create_new_wallet': 'Create New Wallet',
      'import_wallet': 'Import Wallet',
      'export_keys': 'Export Keys',
      'delete_wallet_q': 'Delete Wallet?',
      'delete_warning': 'This will remove the wallet from this device. Make sure you have your seed phrase backed up.',
      'cancel': 'CANCEL',
      'delete': 'DELETE',
      'wallet_deleted': 'Wallet deleted successfully',
      'import_title': 'Import Wallet',
      'import_desc': 'Enter your 12-word seed phrase to recover access.',
      'wallet_name': 'Wallet Name',
      'seed_phrase': 'Seed Phrase',
      'paste': 'PASTE',
      'security_warning': 'Never share your seed phrase. Anyone with it can steal your funds.',
      'export_title': 'Backup',
      'danger': 'DANGER!',
      'danger_desc': 'Never share your Private Key or Seed Phrase. Irreversible loss of funds may occur.',
      'public_address': 'Public Address',
      'private_key': 'Private Key',
      'understand_close': 'UNDERSTAND & CLOSE',
      'copied': 'copied to clipboard',
      'language': 'Language',
      'logout': 'Logout',
      'logout_warning_title': 'Logout & Wipe Data',
      'logout_warning_desc': 'This will remove ALL wallets from this device. You will need your seed phrases to recover them. Are you sure?',
      'no_wallets': 'No wallets configured',
      'create_wallet': 'Create Wallet',
      'import_with_seed': 'Import with Seed Phrase',
      'your_tokens': 'Your Tokens',
      'network': 'Network',
      'mainnet': 'Aptos Mainnet',
      'testnet': 'Aptos Testnet',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
