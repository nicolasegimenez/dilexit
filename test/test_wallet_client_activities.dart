import 'package:flutter_test/flutter_test.dart';
import 'package:aptos/aptos.dart';
import 'package:aptos/indexer_client.dart';
import 'package:dilexit/data/aptos_wallet_client.dart';

void main() {
  test('Fetch activities with new client', () async {
    final client = AptosClient('https://api.testnet.aptoslabs.com/v1');
    final indexer = IndexerClient('https://api.testnet.aptoslabs.com/v1/graphql');
    final walletClient = AptosWalletClient(client, indexer);
    
    try {
      // get latest transactions to find a testnet address
      final txs = await client.getTransactions(limit: 5);
      String? testAddress;
      for (var tx in txs) {
        if (tx['sender'] != null) {
          testAddress = tx['sender'];
          break;
        }
      }
      
      if (testAddress == null) {
        print('No sender found in latest txs');
        return;
      }
      
      print('Found testnet address: $testAddress');
      
      final activities = await walletClient.getCoinActivities(testAddress);
      print('Activities count: ${activities.length}');
      for (var act in activities) {
        print('Type: ${act.activityType} - Amount: ${act.amount} - Version: ${act.transactionVersion}');
      }
    } catch (e) {
      print('Error: $e');
    }
  });
}
