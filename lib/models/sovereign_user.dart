import 'package:aptos/aptos.dart';
import 'package:aptos/coin_client.dart';

/// Represents the user's "Sovereign Identity" on the Aptos blockchain.
///
/// This model encapsulates the user's wallet credentials and balance.
/// All fields are immutable to prevent unexpected mutations in the UI layer.
///
/// Usage:
/// ```dart
/// final account = AptosAccount.generateAccount(mnemonics);
/// final client = AptosClient(Constants.testnetAPI);
/// final user = await SovereignUser.fetchAndCreate(account, client);
/// ```
class SovereignUser {
  /// The private key in hexadecimal format.
  /// WARNING: Never expose this value in logs or UI.
  final String privateKey;

  /// The public address on the Aptos blockchain.
  final String publicAddress;

  /// The account balance in octas (1 APT = 10^8 octas).
  /// Uses BigInt because blockchain values can exceed normal int limits.
  final BigInt balance;

  /// Creates a new [SovereignUser] instance.
  ///
  /// All parameters are required to ensure a valid user state.
  const SovereignUser({
    required this.privateKey,
    required this.publicAddress,
    required this.balance,
  });

  /// Factory method to create a [SovereignUser] by fetching data from the blockchain.
  ///
  /// Takes an [AptosAccount] and an [AptosClient] (configured for testnet/mainnet)
  /// and queries the on-chain balance.
  ///
  /// Throws an exception if the RPC node is unreachable or returns an error.
  ///
  /// Example:
  /// ```dart
  /// final user = await SovereignUser.fetchAndCreate(account, client);
  /// print('Balance: ${user.balanceInApt} APT');
  /// ```
  static Future<SovereignUser> fetchAndCreate(
    AptosAccount account,
    AptosClient client,
  ) async {
    try {
      // Instantiate CoinClient to interact with APT tokens
      final coinClient = CoinClient(client);

      // Fetch the on-chain balance
      final balance = await coinClient.checkBalance(account.address);

      return SovereignUser(
        privateKey: account.toPrivateKeyObject().privateKeyHex!,
        publicAddress: account.address,
        balance: balance,
      );
    } catch (e) {
      // Re-throw with context for better error handling upstream
      throw Exception('Failed to fetch account balance: $e');
    }
  }

  /// Creates a new [SovereignUser] with a zero balance.
  ///
  /// Useful for creating a user instance before the first balance fetch,
  /// or when working offline.
  factory SovereignUser.withZeroBalance(AptosAccount account) {
    return SovereignUser(
      privateKey: account.toPrivateKeyObject().privateKeyHex!,
      publicAddress: account.address,
      balance: BigInt.zero,
    );
  }

  /// Returns the balance converted to APT (from octas).
  ///
  /// 1 APT = 100,000,000 octas (10^8)
  double get balanceInApt => balance / BigInt.from(100000000);

  /// Returns a formatted balance string for display.
  ///
  /// Example: "1.5000 APT"
  String get formattedBalance => '${balanceInApt.toStringAsFixed(4)} APT';

  /// Creates a copy of this [SovereignUser] with the given fields replaced.
  ///
  /// Useful for updating only the balance without re-passing credentials.
  ///
  /// Example:
  /// ```dart
  /// final updatedUser = user.copyWith(balance: newBalance);
  /// ```
  SovereignUser copyWith({
    String? privateKey,
    String? publicAddress,
    BigInt? balance,
  }) {
    return SovereignUser(
      privateKey: privateKey ?? this.privateKey,
      publicAddress: publicAddress ?? this.publicAddress,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'SovereignUser(address: $publicAddress, balance: $formattedBalance)';
  }
}
