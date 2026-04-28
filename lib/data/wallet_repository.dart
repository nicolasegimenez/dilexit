/// Data layer: Wallet Repository
/// Coordinates between domain entities and data sources
import 'package:aptos/aptos.dart';
import 'package:dilexit/domain/wallet_entity.dart';
import 'package:dilexit/data/aptos_wallet_client.dart';
import 'package:dilexit/models/wallet_activity.dart';
import 'package:dilexit/models/token_balance.dart';

class WalletRepository {
  final AptosWalletClient _walletClient;

  WalletRepository(this._walletClient);

  void updateNetwork(String apiUrl, String indexerUrl) {
    _walletClient.updateClient(apiUrl, indexerUrl);
  }

  /// Fetches balance from blockchain for a given address
  Future<BigInt> getBalance(String address) async {
    return await _walletClient.fetchBalance(address);
  }

  /// Fetches balance from blockchain for a given wallet
  Future<WalletEntity> fetchBalance(WalletEntity wallet) async {
    final balance = await _walletClient.fetchBalance(wallet.publicAddress);
    return wallet.copyWith(balance: balance);
  }

  /// Registers a wallet on-chain using faucet (testnet only)
  Future<void> registerOnChain(String privateKey) async {
    final account = AptosAccount.fromPrivateKey(privateKey);
    await _walletClient.createWalletOnChain(account);
  }

  /// Creates wallet both locally and on blockchain
  Future<(WalletEntity, String)> createWallet() async {
    final mnemonics = AptosAccount.generateMnemonic();
    final account = AptosAccount.generateAccount(mnemonics);
    final wallet = WalletEntity.zero(account);

    await _walletClient.createWalletOnChain(account);

    return (wallet, mnemonics);
  }

  /// Imports existing wallet from mnemonics
  Future<WalletEntity> importWallet(String mnemonics) async {
    final account = AptosAccount.generateAccount(mnemonics);
    final wallet = WalletEntity.zero(account);

    // Fetch the actual balance from the chain
    final balance = await _walletClient.fetchBalance(wallet.publicAddress);

    return wallet.copyWith(balance: balance);
  }

  /// Transfers APT to a receiver
  Future<String> transferApt(String mnemonics, String receiverAddress, BigInt amount) async {
    final senderAccount = AptosAccount.generateAccount(mnemonics);
    return await _walletClient.transfer(senderAccount, receiverAddress, amount);
  }

  /// Fetches transaction history for a given address
  Future<List<WalletActivity>> getCoinActivities(String address) async {
    return await _walletClient.getCoinActivities(address);
  }

  /// Fetches tokens and balances for a given address
  Future<List<TokenBalance>> getAccountTokens(String address) async {
    return await _walletClient.getAccountTokens(address);
  }
}

// Error types for better error handling

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class InsufficientFundsException implements Exception {
  final String message;
  InsufficientFundsException(this.message);
  @override
  String toString() => message;
}

class TransactionFailedException implements Exception {
  final String message;
  TransactionFailedException(this.message);
  @override
  String toString() => message;
}
