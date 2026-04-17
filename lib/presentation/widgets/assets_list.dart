import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AssetsList extends StatelessWidget {
  const AssetsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Assets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AssetTile(
          symbol: 'APT',
          name: 'Aptos',
          balance: '1,250.75',
          usdValue: '\$15,634.38',
        ),
        const Divider(color: Colors.white24),
        _AssetTile(
          symbol: 'USDT',
          name: 'Tether',
          balance: '0.00113',
          usdValue: '\$0.01',
        ),
        const Divider(color: Colors.white24),
        _AssetTile(
          symbol: 'WBTC',
          name: 'Wrapped BTC',
          balance: '0.006',
          usdValue: '\$0.01',
        ),
      ],
    );
  }
}

class _AssetTile extends StatelessWidget {
  final String symbol;
  final String name;
  final String balance;
  final String usdValue;

  const _AssetTile({
    required this.symbol,
    required this.name,
    required this.balance,
    required this.usdValue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primary.withAlpha(51),
        child: Text(
          symbol.substring(0, 1),
          style: const TextStyle(color: AppTheme.primary),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(symbol, style: TextStyle(color: Colors.grey[400])),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            balance,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            usdValue,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
