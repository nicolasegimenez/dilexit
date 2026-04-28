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
    final decimals = metadata['decimals'] ?? 8; // Default 8 (como APT)
    final rawAmount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0;
    
    // Formatear el monto dividiendo por la cantidad de decimales
    // Nota: math.pow no está disponible sin importar dart:math, usando multiplicación simple para 10^decimals
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
