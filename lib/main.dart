import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aptos/aptos.dart';


import 'package:dilexit/presentation/providers/auth_provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';
import 'package:dilexit/constants/network.dart';
import 'package:dilexit/presentation/theme/app_theme.dart';
import 'package:dilexit/presentation/screens/splash_screen.dart';
import 'package:dilexit/presentation/screens/pin_login_screen.dart';
import 'package:dilexit/presentation/screens/home_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// ponytail: YAGNI localizations, single language app. Hardcoded strings used instead.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final aptosClient = AptosClient(Network.testnet.apiUrl);
  final storageService = const FlutterSecureStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storageService)),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(aptosClient, storageService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dilexit Wallet',
      theme: AppTheme.darkTheme,
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
