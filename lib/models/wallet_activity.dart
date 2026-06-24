class WalletActivity {
  final String activityType;
  final double amount;
  final int transactionVersion;
  final bool isTransactionSuccess;
  final DateTime timestamp;

  WalletActivity({
    required this.activityType,
    required this.amount,
    required this.transactionVersion,
    this.isTransactionSuccess = true,
    required this.timestamp,
  });

  factory WalletActivity.fromJson(Map<String, dynamic> json) {
    return WalletActivity(
      activityType: json['type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      transactionVersion: json['transaction_version'] ?? 0,
      isTransactionSuccess: true,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
