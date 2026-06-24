import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';
import 'package:dilexit/presentation/widgets/balance_card.dart';
import 'package:dilexit/presentation/widgets/action_buttons.dart';
import 'package:dilexit/presentation/screens/send_screen.dart';
import 'package:dilexit/presentation/screens/settings_screen.dart';
import 'package:dilexit/presentation/screens/receive_screen.dart';
import 'package:dilexit/presentation/screens/activity_screen.dart';

import 'package:dilexit/models/token_balance.dart';

import 'package:dilexit/constants/network.dart';
import 'package:dilexit/presentation/screens/pin_setup_screen.dart';
import 'package:dilexit/presentation/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isGenerating = false;

  final List<Widget> _pages = [
    const _HomeView(),
    const ActivityScreen(),
    const Center(
      child: Text('Browser', style: TextStyle(color: Colors.white)),
    ),
    const SettingsScreen(),
  ];

  void _showDeleteConfirmation(
    BuildContext context,
    String address,
    WalletProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete Wallet?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '${'This will remove the wallet from this device. Make sure you have your seed phrase backed up.'} (${address.substring(0, 6)}...)',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);

              final success = await provider.removeWallet(address);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wallet deleted successfully'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('DELETE', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAccountsModal(BuildContext context) {
    final provider = context.read<WalletProvider>();
    final wallet = provider.state.wallet;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (provider.state.savedWallets.isEmpty && wallet == null)
                  Text(
                    'No wallets configured',
                    style: const TextStyle(color: Colors.white70),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...provider.state.savedWallets.map((w) {
                            final address = w['publicAddress'] as String;
                            final isSelected =
                                wallet != null &&
                                address == wallet.publicAddress;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                        )
                                      : Border.all(color: Colors.white10),
                                ),
                                child: ListTile(
                                  onTap: () async {
                                    if (!isSelected) {
                                      Navigator.pop(context);
                                      final success = await provider
                                          .switchWallet(address);
                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${'copied to clipboard'} ${address.substring(0, 6)}...',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white10,
                                    child: Icon(
                                      Icons.account_balance_wallet,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          w['name'] ??
                                              (isSelected
                                                  ? 'Main Account'
                                                  : 'Saved Wallet'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      FutureBuilder<double>(
                                        future: provider.getOtherWalletBalance(
                                          address,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1,
                                              ),
                                            );
                                          }
                                          return Text(
                                            '${snapshot.data?.toStringAsFixed(2) ?? '0.00'} APT',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.8),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${address.substring(0, 8)}...${address.substring(address.length - 6)}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => _showDeleteConfirmation(
                                      context,
                                      address,
                                      provider,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleCreateWallet(BuildContext context) async {
    final provider = context.read<WalletProvider>();
    setState(() => _isGenerating = true);
    final result = await provider.generateNewWalletData();
    setState(() => _isGenerating = false);

    if (result != null && context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            _SeedBackupSheet(wallet: result.$1, mnemonics: result.$2),
      );
    }
  }

  void _showExportSheet(BuildContext context) {
    final provider = context.read<WalletProvider>();
    if (provider.state.wallet == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExportKeysSheet(
        address: provider.state.wallet!.publicAddress,
        privateKey: provider.state.wallet!.privateKey,
        mnemonics: provider.state.mnemonics ?? 'Not available',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = context.watch<WalletProvider>().state;
    final wallet = walletState.wallet;

    // If wallet is null, we show the onboarding view without the bottom bar
    if (wallet == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              const _HomeView(),
              if (walletState.isLoading)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          walletState.loadingMessage ?? 'Loading...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationDrawer(
        backgroundColor: Colors.grey[900],
        indicatorColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.2),
        onDestinationSelected: (int index) {
          Navigator.pop(context);
          if (index == 0) {
            _showAccountsModal(context);
          } else if (index == 1) {
            _handleCreateWallet(context);
          } else if (index == 2) {
            showImportDialog(context);
          } else if (index == 3) {
            _showExportSheet(context);
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 16, 10),
            child: Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
          ),
          NavigationDrawerDestination(
            label: Text(
              'Change Wallets',
              style: const TextStyle(color: Colors.white),
            ),
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white70,
            ),
            selectedIcon: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
            child: Divider(color: Colors.white10),
          ),
          NavigationDrawerDestination(
            label: Text(
              'Create New Wallet',
              style: const TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
          ),
          NavigationDrawerDestination(
            label: Text(
              'Import Wallet',
              style: const TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.download_rounded, color: Colors.white70),
          ),
          NavigationDrawerDestination(
            label: Text(
              'Export Keys',
              style: const TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.vpn_key_outlined, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 20),
            child: Text(
              'Dilexit Wallet v1.0.0',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _pages[_selectedIndex],
            if (context.watch<WalletProvider>().state.isLoading &&
                context.read<WalletProvider>().state.wallet != null)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        context.read<WalletProvider>().state.loadingMessage ??
                            'Cargando...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.wallet_rounded),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final state = provider.state;
    final theme = Theme.of(context);

    if (state.wallet == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 100,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Dilexit Wallet',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your secure gateway to the Aptos ecosystem. Manage your assets with total sovereignty.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isCreating
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PinSetupScreen(
                            onSuccess: () async {
                              Navigator.pop(context); // close PinSetupScreen
                              setState(() => _isCreating = true);
                              final result = await provider
                                  .generateNewWalletData();
                              setState(() => _isCreating = false);

                              if (result != null && context.mounted) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => _SeedBackupSheet(
                                    wallet: result.$1,
                                    mnemonics: result.$2,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      'Create Wallet'.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => showImportDialog(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Import with Seed Phrase',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'v1.0.0 - Built on Aptos',
              style: TextStyle(color: Colors.white24, fontSize: 12),
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
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                          Text(
                            state.currentNetwork == Network.mainnet
                                ? 'Aptos Mainnet'
                                : 'Aptos Testnet',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ),
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
                MaterialPageRoute(builder: (_) => const SendScreen()),
              ),
              onReceive: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiveScreen()),
              ),
            ),
            const SizedBox(height: 20),
            if (state.tokens.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Tokens',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...state.tokens.map((token) => _TokenTile(token: token)),
            ] else ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.token, color: Colors.greenAccent),
                    SizedBox(width: 16),
                    Text(
                      'APT (Aptos)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text('Activo', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TokenTile extends StatelessWidget {
  final TokenBalance token;

  const _TokenTile({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              token.symbol.isNotEmpty ? token.symbol[0] : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  token.symbol,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            token.amount
                .toStringAsFixed(4)
                .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), ''),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

void showImportDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ImportWalletSheet(),
  );
}

class _ImportWalletSheet extends StatefulWidget {
  const _ImportWalletSheet();

  @override
  State<_ImportWalletSheet> createState() => _ImportWalletSheetState();
}

class _ImportWalletSheetState extends State<_ImportWalletSheet> {
  final _formKey = GlobalKey<FormState>();
  final _mnemonicController = TextEditingController();
  final _nameController = TextEditingController();
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _mnemonicController.addListener(_updateWordCount);
  }

  void _updateWordCount() {
    final text = _mnemonicController.text.trim();
    setState(() {
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _mnemonicController.text = data!.text!;
      });
    }
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Import Wallet',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 12-word seed phrase to recover access.',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Wallet Name',
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Error' : null,
              ),
              const SizedBox(height: 20),

              Stack(
                alignment: Alignment.topRight,
                children: [
                  TextFormField(
                    controller: _mnemonicController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Seed Phrase',
                      hintText: 'word1 word2 word3...',
                      alignLabelWithHint: true,
                      helperText: '$_wordCount / 12',
                    ),
                    validator: (v) =>
                        (v == null ||
                            v.trim().split(RegExp(r'\s+')).length != 12)
                        ? 'Error'
                        : null,
                  ),
                  TextButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste, size: 16),
                    label: Text('PASTE'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Never share your seed phrase. Anyone with it can steal your funds.',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final mnemonics = _mnemonicController.text.trim();
                    final name = _nameController.text.trim();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PinSetupScreen(
                          onSuccess: () {
                            Navigator.pop(context); // close pin setup
                            context.read<WalletProvider>().importWallet(
                              mnemonics,
                              name: name,
                            );
                            Navigator.pop(context); // close bottom sheet
                          },
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text('Import Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportKeysSheet extends StatelessWidget {
  final String address;
  final String privateKey;
  final String mnemonics;

  const _ExportKeysSheet({
    required this.address,
    required this.privateKey,
    required this.mnemonics,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ${'copied to clipboard'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Backup',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DANGER!',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Never share your Private Key or Seed Phrase. Irreversible loss of funds may occur.',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _KeySection(
              label: 'Private Key',
              value: privateKey,
              isSensitive: true,
              onCopy: () =>
                  _copyToClipboard(context, privateKey, 'Private Key'),
            ),
            const SizedBox(height: 20),

            _KeySection(
              label: 'Seed Phrase',
              value: mnemonics,
              isSensitive: true,
              onCopy: () => _copyToClipboard(context, mnemonics, 'Seed Phrase'),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
              ),
              child: Text('UNDERSTAND & CLOSE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeySection extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool isSensitive;

  const _KeySection({
    required this.label,
    required this.value,
    required this.onCopy,
    this.isSensitive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isSensitive ? Colors.orangeAccent : Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: Colors.greenAccent,
                ),
                onPressed: onCopy,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeedBackupSheet extends StatefulWidget {
  final WalletEntity wallet;
  final String mnemonics;

  const _SeedBackupSheet({required this.wallet, required this.mnemonics});

  @override
  State<_SeedBackupSheet> createState() => _SeedBackupSheetState();
}

class _SeedBackupSheetState extends State<_SeedBackupSheet> {
  bool _isFinalizing = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonics.split(' ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.security_rounded,
            color: Colors.greenAccent,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Seed Phrase',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Save these 12 words in a safe place. They are the only way to recover your funds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(words.length, (index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${index + 1}.',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        words[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isFinalizing
                ? null
                : () async {
                    setState(() => _isFinalizing = true);
                    await context.read<WalletProvider>().finalizeWalletCreation(
                      widget.wallet,
                      widget.mnemonics,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
            ),
            child: _isFinalizing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text('HE GUARDADO MI FRASE SEMILLA'),
          ),
        ],
      ),
    );
  }
}
