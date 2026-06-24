import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aptos/aptos.dart';
import 'package:aptos/indexer_client.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:dilexit/presentation/providers/auth_provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';

import 'package:dilexit/presentation/providers/locale_provider.dart';

import 'package:dilexit/data/aptos_wallet_client.dart';
import 'package:dilexit/data/secure_storage_service.dart';
import 'package:dilexit/constants/network.dart';
import 'package:dilexit/presentation/theme/app_theme.dart';
import 'package:dilexit/presentation/screens/splash_screen.dart';
import 'package:dilexit/presentation/screens/pin_login_screen.dart';
import 'package:dilexit/presentation/screens/home_screen.dart';
import 'package:dilexit/l10n/app_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final aptosClient = AptosClient(Network.testnet.apiUrl);
  final indexerClient = IndexerClient(Network.testnet.indexerUrl);
  final walletClient = AptosWalletClient(aptosClient, indexerClient);
  
  final storageService = SecureStorageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storageService)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(storageService)),
        ChangeNotifierProvider(create: (_) => WalletProvider(walletClient, storageService)),
        
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dilexit Wallet',
      theme: AppTheme.darkTheme,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;

    switch (authState) {
      case AuthState.loading:
        return const SplashScreen();
      case AuthState.locked:
        return const PinLoginScreen();
      case AuthState.noWallet:
      case AuthState.unlocked:
        return const HomeScreen();
    }
  }
}
