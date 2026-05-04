import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dilexit/data/wallet_repository.dart';
import 'package:dilexit/data/aptos_wallet_client.dart';
import 'package:aptos/aptos.dart';
import 'package:aptos/indexer_client.dart';

void main() {
  testWidgets('create wallet', (WidgetTester tester) async {
    try {
      final client = AptosClient('https://fullnode.testnet.aptoslabs.com/v1');
      final indexerClient = IndexerClient('https://indexer.testnet.aptoslabs.com/v1/graphql');
      final (wallet, mnemonics) = await WalletRepository(AptosWalletClient(client, indexerClient)).createWallet();
      print('Wallet created successfully: ${wallet.publicAddress}');
      print('Mnemonics: $mnemonics');
    } catch(e) {
      print('Failed to create wallet: $e');
    }
  });
}
