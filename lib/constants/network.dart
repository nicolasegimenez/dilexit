/// Network configuration constants for Aptos blockchain.
///
/// Currently configured for TESTNET.
/// Change to mainnet URLs when ready for production.
class NetworkConstants {
  NetworkConstants._();

  /// Aptos Testnet RPC endpoint.
  static const String testnetApi = 'https://fullnode.testnet.aptoslabs.com/v1';

  /// Aptos Mainnet RPC endpoint (for future use).
  static const String mainnetApi = 'https://fullnode.mainnet.aptoslabs.com/v1';

  /// Aptos Devnet RPC endpoint (for development).
  static const String devnetApi = 'https://fullnode.devnet.aptoslabs.com/v1';

  /// Current active network endpoint.
  /// Change this to switch between networks.
  static const String currentApi = testnetApi;

  /// Testnet faucet URL for requesting test tokens.
  static const String testnetFaucet = 'https://faucet.testnet.aptoslabs.com';

  /// Explorer URL for viewing transactions.
  static const String explorerUrl = 'https://explorer.aptoslabs.com';
}
