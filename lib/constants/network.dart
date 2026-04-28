enum Network {
  mainnet(
    'Mainnet', 
    'https://api.mainnet.aptoslabs.com/v1', 
    'https://api.mainnet.aptoslabs.com/v1/graphql'
  ),
  testnet(
    'Testnet', 
    'https://api.testnet.aptoslabs.com/v1', 
    'https://api.testnet.aptoslabs.com/v1/graphql'
  ),
  devnet(
    'Devnet', 
    'https://api.devnet.aptoslabs.com/v1', 
    'https://api.devnet.aptoslabs.com/v1/graphql'
  );

  final String displayName;
  final String apiUrl;
  final String indexerUrl;
  const Network(this.displayName, this.apiUrl, this.indexerUrl);
}

class NetworkConstants {
  NetworkConstants._();
  static const String testnetFaucet = 'https://faucet.testnet.aptoslabs.com';
  static const String explorerUrl = 'https://explorer.aptoslabs.com';
}
