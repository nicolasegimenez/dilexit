import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final String formattedBalance;
  final bool isLoading;
  final VoidCallback onRefresh;

  const BalanceCard({
    super.key,
    required this.formattedBalance,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formattedBalance,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
