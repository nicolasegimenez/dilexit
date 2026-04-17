import 'package:aptos/aptos.dart';

/// Domain entity: Represents a wallet on the Aptos blockchain
class WalletEntity {
  final String privateKey;
  final String publicAddress;
  final BigInt balance;

  const WalletEntity({
    required this.privateKey,
    required this.publicAddress,
    required this.balance,
  });

  factory WalletEntity.fromAptosAccount(AptosAccount account, BigInt balance) {
    return WalletEntity(
      privateKey: account.toPrivateKeyObject().privateKeyHex!,
      publicAddress: account.address,
      balance: balance,
    );
  }

  factory WalletEntity.zero(AptosAccount account) {
    return WalletEntity(
      privateKey: account.toPrivateKeyObject().privateKeyHex!,
      publicAddress: account.address,
      balance: BigInt.zero,
    );
  }

  WalletEntity copyWith({
    String? privateKey,
    String? publicAddress,
    BigInt? balance,
  }) {
    return WalletEntity(
      privateKey: privateKey ?? this.privateKey,
      publicAddress: publicAddress ?? this.publicAddress,
      balance: balance ?? this.balance,
    );
  }

  double get balanceInApt => balance / BigInt.from(100000000);

  String get formattedBalance => '${balanceInApt.toStringAsFixed(4)} APT';
}
