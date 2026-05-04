import 'package:aptos/aptos.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:dilexit/domain/wallet_entity.dart';
import 'package:dilexit/data/wallet_repository.dart';

abstract class WalletUseCase {
  Future<WalletEntity> createWallet();
  Future<WalletEntity> importWallet(String mnemonics);
}

class CreateWallet implements WalletUseCase {
  final AptosClient _client;

  CreateWallet(this._client);

  @override
  Future<WalletEntity> createWallet() async {
    final result = await compute(WalletRepository.generateNewWalletTask, null);
    final account = AptosAccount.fromPrivateKey(result.$3);
    return WalletEntity.zero(account);
  }

  @override
  Future<WalletEntity> importWallet(String mnemonics) async {
    final result = await compute(WalletRepository.importWalletTask, mnemonics);
    final account = AptosAccount.fromPrivateKey(result.$2);
    return WalletEntity.zero(account);
  }
}

class ImportWallet implements WalletUseCase {
  ImportWallet(AptosClient client);

  @override
  Future<WalletEntity> createWallet() async {
    final result = await compute(WalletRepository.generateNewWalletTask, null);
    final account = AptosAccount.fromPrivateKey(result.$3);
    return WalletEntity.zero(account);
  }

  @override
  Future<WalletEntity> importWallet(String mnemonics) async {
    final result = await compute(WalletRepository.importWalletTask, mnemonics);
    final account = AptosAccount.fromPrivateKey(result.$2);
    return WalletEntity.zero(account);
  }
}
