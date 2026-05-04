import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';
import 'package:dilexit/presentation/providers/locale_provider.dart';
import 'package:dilexit/l10n/app_localizations.dart';
import 'package:dilexit/constants/network.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = localeProvider.locale;
    final currentNetwork = walletProvider.state.currentNetwork;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Selector
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.language, color: Colors.blueAccent),
              title: Text(l10n.translate('language'), style: const TextStyle(color: Colors.white)),
              trailing: DropdownButton<String>(
                value: 'en',
                dropdownColor: Colors.grey[900],
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (String? code) {
                  if (code != null) {
                    localeProvider.setLocale(Locale(code));
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Network Selector
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.hub_outlined, color: Colors.greenAccent),
              title: Text(l10n.translate('network'), style: const TextStyle(color: Colors.white)),
              trailing: DropdownButton<Network>(
                value: currentNetwork,
                dropdownColor: Colors.grey[900],
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: Network.mainnet, 
                    child: Text(l10n.translate('mainnet'), style: const TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: Network.testnet, 
                    child: Text(l10n.translate('testnet'), style: const TextStyle(color: Colors.white)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(l10n.translate('logout'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.translate('logout_warning_title'))),
                      ],
                    ),
                    content: Text(
                      l10n.translate('logout_warning_desc'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          l10n.translate('cancel'),
                          style: const TextStyle(color: Colors.white54),
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
                        child: Text(l10n.translate('logout').toUpperCase()),
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
