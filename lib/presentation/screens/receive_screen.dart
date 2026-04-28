import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';
import 'package:flutter/services.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>().state.wallet;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Receive APT')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 40),
            const Text('Your public address', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                wallet?.publicAddress ?? 'Loading...',
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (wallet != null) {
                  Clipboard.setData(ClipboardData(text: wallet.publicAddress));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Address'),
            ),
          ],
        ),
      ),
    );
  }
}
