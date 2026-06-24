class TokenBalance {
  final String assetType;
  final double amount;
  final String name;
  final String symbol;
  final int decimals;

  TokenBalance({
    required this.assetType,
    required this.amount,
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  factory TokenBalance.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] ?? {};
    final decimals = metadata['decimals'] ?? 8; // Default 8 (like APT)
    final rawAmount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0;

    // Format the amount by dividing by the number of decimals
    // Note: math.pow is not available without importing dart:math, using simple multiplication for 10^decimals
    double divisor = 1.0;
    for (int i = 0; i < decimals; i++) {
      divisor *= 10;
    }

    final formattedAmount = rawAmount / divisor;

    return TokenBalance(
      assetType: json['asset_type'] ?? '',
      amount: formattedAmount,
      name: metadata['name'] ?? 'Unknown Token',
      symbol: metadata['symbol'] ?? '???',
      decimals: decimals,
    );
  }
}
