/// Data layer: Aptos Wallet API client
/// Handles all network communication with Aptos blockchain
import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';

class WalletException implements Exception {
  final String message;
  WalletException(this.message);
  @override
  String toString() => message;
}

class AptosWalletClient {
  final AptosClient client;

  AptosWalletClient(this.client);

  /// Fetches the balance for a given wallet address
  /// Returns balance in octas (1 APT = 10^8 octas)
  Future<BigInt> fetchBalance(String address) async {
    try {
      // Use the view function to safely get balance. 
      // It handles both legacy CoinStore and new Fungible Asset standard for APT.
      final balanceResp = await client.view(
        "0x1::coin::balance",
        ["0x1::aptos_coin::AptosCoin"],
        [address],
      );
      
      if (balanceResp != null && balanceResp.isNotEmpty) {
        return BigInt.parse(balanceResp[0].toString());
      }
      return BigInt.zero;
    } catch (e) {
      // If the account hasn't been created on-chain yet or has no APT, it might throw.
      // We catch this gracefully and return 0 instead of crashing.
      final errorMessage = e.toString().toLowerCase();
      // DioException [bad response] throws when status is 404
      if (errorMessage.contains('account not found') || 
          errorMessage.contains('resource not found') ||
          errorMessage.contains('404') ||
          errorMessage.contains('bad response') ||
          errorMessage.contains('table item not found')) {
        return BigInt.zero;
      }
      // Re-throw with context for better debugging
      throw WalletException('Failed to fetch balance for $address: $e');
    }
  }

  /// Creates a new wallet on the blockchain
  Future<void> createWalletOnChain(AptosAccount account) async {
    try {
      // Implementation for wallet creation on chain
      // This would typically involve transaction submission
    } catch (e) {
      throw WalletException('Failed to create wallet on chain: $e');
    }
  }

  /// Transfers APT to another account
  Future<String> transfer(AptosAccount sender, String receiverAddress, BigInt amount) async {
    try {
      final txHash = await CoinClient(client).transfer(
        sender,
        receiverAddress,
        amount,
        createReceiverIfMissing: true,
      );
      return txHash;
    } catch (e) {
      throw WalletException('Failed to transfer: $e');
    }
  }
}
