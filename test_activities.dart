import 'package:aptos/aptos.dart';
import 'package:aptos/indexer_client.dart';
import 'package:aptos/faucet_client.dart';

void main() async {
  final indexer = IndexerClient('https://indexer.testnet.aptoslabs.com/v1/graphql');
  // Use a known address on testnet if possible, or just print
  // Let's create an account, fund it, and then check activities.
  final account = AptosAccount();
  final client = AptosClient('https://fullnode.testnet.aptoslabs.com/v1');
  
  print('Address: \${account.address}');
  
  try {
    final faucet = FaucetClient.fromClient('https://faucet.testnet.aptoslabs.com', client);
    await faucet.fundAccount(account.address, "100000000"); // 1 APT
    print('Funded account');
    
    // give indexer a sec
    await Future.delayed(Duration(seconds: 3));
    
    final activities = await indexer.getAccountCoinActivity(accountAddress: account.address);
    print('Activities count: \${activities.length}');
    for (var act in activities) {
      print('\${act.activityType} - \${act.amount}');
    }
  } catch (e) {
    print('Error: \$e');
  }
}
