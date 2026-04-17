// lib/presentation/widgets/network_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/network.dart';
import '../providers/wallet_provider.dart';

class NetworkSelector extends StatelessWidget {
  const NetworkSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final currentNetwork = context.select(
      (WalletProvider p) => p.state.currentNetwork,
    );
    return ListTile(
      leading: const Icon(Icons.wifi),
      title: const Text('Network'),
      trailing: DropdownButton<Network>(
        value: currentNetwork,
        underline: const SizedBox(),
        items: Network.values.map((network) {
          return DropdownMenuItem(
            value: network,
            child: Text(network.displayName),
          );
        }).toList(),
        onChanged: (newNetwork) {
          if (newNetwork != null) {
            context.read<WalletProvider>().changeNetwork(newNetwork);
          }
        },
      ),
    );
  }
}
