import 'package:aptos/aptos.dart';
import 'package:Dilexit/domain/wallet_entity.dart';

abstract class WalletUseCase {
  Future<WalletEntity> createWallet();
  Future<WalletEntity> importWallet(String mnemonics);
}

class CreateWallet implements WalletUseCase {
  final AptosClient _client;

  CreateWallet(this._client);

  @override
  Future<WalletEntity> createWallet() async {
    final mnemonics = AptosAccount.generateMnemonic();
    final account = AptosAccount.generateAccount(mnemonics);
    return WalletEntity.zero(account);
  }

  @override
  Future<WalletEntity> importWallet(String mnemonics) async {
    final account = AptosAccount.generateAccount(mnemonics);
    return WalletEntity.zero(account);
  }
}

class ImportWallet implements WalletUseCase {
  ImportWallet(AptosClient client);

  @override
  Future<WalletEntity> createWallet() async {
    final mnemonics = AptosAccount.generateMnemonic();
    final account = AptosAccount.generateAccount(mnemonics);
    return WalletEntity.zero(account);
  }

  @override
  Future<WalletEntity> importWallet(String mnemonics) async {
    final account = AptosAccount.generateAccount(mnemonics);
    return WalletEntity.zero(account);
  }
}
