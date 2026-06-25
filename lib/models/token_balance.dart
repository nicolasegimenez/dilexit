import 'dart:math' as math;
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

    // ponytail: replaced custom loop with stdlib
    final formattedAmount = rawAmount / math.pow(10, decimals);

    return TokenBalance(
      assetType: json['asset_type'] ?? '',
      amount: formattedAmount,
      name: metadata['name'] ?? 'Unknown Token',
      symbol: metadata['symbol'] ?? '???',
      decimals: decimals,
    );
  }
}
