// lib/presentation/widgets/network_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/network.dart';
import '../providers/wallet_provider.dart';
import '../providers/notification_provider.dart';
import '../../models/app_notification.dart';

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
          String balance = '0';
          if (network == Network.testnet) balance = '9.98';
          if (network == Network.mainnet) balance = '0';
          
          return DropdownMenuItem(
            value: network,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(network.displayName),
                const SizedBox(width: 8),
                Text(
                  '($balance APT)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (newNetwork) {
          if (newNetwork != null) {
            context.read<WalletProvider>().changeNetwork(newNetwork);
            context.read<NotificationProvider>().addNotification(
              title: 'Network Changed',
              message: 'You are now on ${newNetwork.displayName}',
              type: NotificationType.info,
            );
          }
        },
      ),
    );
  }
}
