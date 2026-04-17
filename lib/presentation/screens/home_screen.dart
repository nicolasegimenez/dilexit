import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dilexit/presentation/providers/wallet_provider.dart';
import 'package:Dilexit/presentation/widgets/balance_card.dart';
import 'package:Dilexit/presentation/widgets/action_buttons.dart';
import 'package:Dilexit/presentation/screens/send_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomeView(),
    const Center(child: Text('Actividad (Próximamente)', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Browser (Próximamente)', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Ajustes (Próximamente)', style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wallet_rounded), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Actividad'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final state = provider.state;
    final theme = Theme.of(context);

    if (state.wallet == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            const Text('No tienes una wallet configurada', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.createWallet(),
              child: const Text('Crear Nueva Wallet'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => provider.fetchBalance(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Aptos Mainnet', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.notifications_none, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 40),
            BalanceCard(
              formattedBalance: state.wallet!.formattedBalance,
              isLoading: state.isLoadingBalance,
              onRefresh: () => provider.fetchBalance(),
            ),
            ActionButtons(
              onSend: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const SendScreen())
              ),
              onReceive: () {
                // TODO: ReceiveScreen
              },
            ),
            const SizedBox(height: 20),
            // TODO: AssetsList
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.token, color: Colors.greenAccent),
                  SizedBox(width: 16),
                  Text('APT (Aptos)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Text('Activo', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
