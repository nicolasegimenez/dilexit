import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dilexit/data/wallet_repository.dart';
import 'package:dilexit/data/aptos_wallet_client.dart';
import 'package:aptos/aptos.dart';

void main() {
  testWidgets('create wallet', (WidgetTester tester) async {
    try {
      final (wallet, mnemonics) = await WalletRepository(AptosWalletClient(AptosClient('https://fullnode.testnet.aptoslabs.com/v1'))).createWallet();
      print('Wallet created successfully: ${wallet.publicAddress}');
      print('Mnemonics: $mnemonics');
    } catch(e) {
      print('Failed to create wallet: $e');
    }
  });
}
