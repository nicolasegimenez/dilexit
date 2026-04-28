import 'package:flutter_test/flutter_test.dart';
import 'package:aptos/aptos.dart';
import 'package:aptos/indexer_client.dart';

void main() {
  test('Fetch activities', () async {
    final indexer = IndexerClient('https://indexer.testnet.aptoslabs.com/v1/graphql');
    final client = AptosClient('https://fullnode.testnet.aptoslabs.com/v1');
    
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
      
      final activities = await indexer.getAccountCoinActivity(accountAddress: testAddress);
      print('Activities count: ${activities.length}');
      for (var act in activities) {
        print('Type: ${act.activityType} - Amount: ${act.amount} - Gas? ${act.isGasFee} - Func: ${act.entryFunctionIdStr}');
      }
    } catch (e) {
      print('Error: $e');
    }
  });
}
