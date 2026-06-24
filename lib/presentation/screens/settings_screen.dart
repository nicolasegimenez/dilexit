import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';
import 'package:dilexit/constants/network.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final currentNetwork = walletProvider.state.currentNetwork;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Network Selector
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.hub_outlined,
                color: Colors.greenAccent,
              ),
              title: const Text(
                'Network',
                style: TextStyle(color: Colors.white),
              ),
              trailing: DropdownButton<Network>(
                value: currentNetwork,
                dropdownColor: Colors.grey[900],
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: Network.mainnet,
                    child: Text(
                      'Aptos Mainnet',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: Network.testnet,
                    child: Text(
                      'Aptos Testnet',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (Network? net) {
                  if (net != null) {
                    walletProvider.changeNetwork(net);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Text('Logout & Wipe Data')),
                      ],
                    ),
                    content: const Text(
                      'This will remove ALL wallets from this device. You will need your seed phrases to recover them. Are you sure?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await walletProvider.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('LOGOUT'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
