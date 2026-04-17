import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aptos/aptos.dart';

import 'package:Dilexit/presentation/providers/wallet_provider.dart';
import 'package:Dilexit/data/wallet_repository.dart';
import 'package:Dilexit/data/aptos_wallet_client.dart';
import 'package:Dilexit/data/secure_storage_service.dart';
import 'package:Dilexit/constants/network.dart';
import 'package:Dilexit/presentation/theme/app_theme.dart';
import 'package:Dilexit/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final aptosClient = AptosClient(NetworkConstants.currentApi);
  final walletClient = AptosWalletClient(aptosClient);
  final repository = WalletRepository(walletClient);
  final storageService = SecureStorageService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => WalletProvider(repository, storageService),
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
      home: const SplashScreen(),
    );
  }
}
