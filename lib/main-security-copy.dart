import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aptos/aptos.dart';
import 'models/sovereign_user.dart';
import 'constants/network.dart';

void main() {
  // runApp es el puente entre el motor de Flutter y tu árbol de widgets
  runApp(const MiHolaMundo());
}

class MiHolaMundo extends StatelessWidget {
  const MiHolaMundo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AptosAccount? _account;
  SovereignUser? _user;
  String? _mnemonics;
  bool _isLoading = false;
  bool _isFetchingBalance = false;

  /// Creates a new Aptos wallet with a randomly generated mnemonic.
  ///
  /// Shows a loading indicator during generation and updates the UI
  /// with the new account details upon completion.
  Future<void> _createWallet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate random 12-word mnemonic
      final mnemonics = AptosAccount.generateMnemonic();
      // Create account from mnemonic
      final newAccount = AptosAccount.generateAccount(mnemonics);

      // Create user with zero balance initially (new wallet has no funds)
      final user = SovereignUser.withZeroBalance(newAccount);

      setState(() {
        _account = newAccount;
        _user = user;
        _mnemonics = mnemonics;
        _isLoading = false;
      });

      // Fetch actual balance from testnet in background
      _fetchBalance(newAccount);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError(context: context, message: 'Error creating wallet: $e');
    }
  }

  /// Fetches the current balance from the blockchain.
  Future<void> _fetchBalance(AptosAccount account) async {
    setState(() {
      _isFetchingBalance = true;
    });

    try {
      final client = AptosClient(NetworkConstants.currentApi);
      final user = await SovereignUser.fetchAndCreate(account, client);

      setState(() {
        _user = user;
        _isFetchingBalance = false;
      });
    } catch (e) {
      // Account may not exist on-chain yet (no transactions)
      setState(() {
        _isFetchingBalance = false;
      });
    }
  }

  /// Opens a dialog to import an existing wallet from a mnemonic phrase.
  ///
  /// Validates that the input contains exactly 12 words and attempts
  /// to generate an account. Shows an error if the mnemonic is invalid.
  void _importSeed() {
    final formKey = GlobalKey<FormState>();
    final seedController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Importar Semilla',
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: seedController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Ingresa tus 12 palabras separadas por espacios',
              hintStyle: TextStyle(color: Colors.grey[500]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.greenAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu frase semilla';
              }
              final palabras = value.trim().split(RegExp(r'\s+'));
              if (palabras.length != 12) {
                return 'La frase debe tener exactamente 12 palabras';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final mnemonics = seedController.text.trim();
                try {
                  final newAccount = AptosAccount.generateAccount(mnemonics);
                  final user = SovereignUser.withZeroBalance(newAccount);
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _account = newAccount;
                    _user = user;
                    _mnemonics = mnemonics;
                  });
                  // Fetch actual balance from testnet
                  _fetchBalance(newAccount);
                } catch (e) {
                  _showError(
                    context: dialogContext,
                    message: 'Invalid mnemonic phrase. Please check your words.',
                  );
                }
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  /// Displays an error message using a SnackBar.
  ///
  /// [context] - The BuildContext to show the SnackBar.
  /// [message] - The error message to display.
  void _showError({required BuildContext context, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(
              'Aptos Wallet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading) ...[
              const CircularProgressIndicator(color: Colors.greenAccent),
              const SizedBox(height: 15),
              Text(
                'Creando wallet...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ] else
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.pressed)) {
                      return Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5);
                    }
                    return null;
                  }),
                ),
                child: const Text('Crear Wallet'),
                onPressed: _createWallet,
              ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.pressed)) {
                    return Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5);
                  }
                  return null;
                }),
              ),
              child: const Text('Importar Semilla'),
              onPressed: _importSeed,
            ),
            if (_user != null) ...[
              const SizedBox(height: 30),
              Text(
                'Tu Identidad Soberana',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 20),
              CajaMnemotecnica(fraseSemilla: _mnemonics!),
              const SizedBox(height: 30),
              // Balance card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Balance',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (_isFetchingBalance)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Text(
                        _user!.formattedBalance,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Dirección:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SelectableText(
                  _user!.publicAddress,
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
              // Refresh balance button
              TextButton.icon(
                onPressed: _account != null ? () => _fetchBalance(_account!) : null,
                icon: const Icon(Icons.refresh, color: Colors.greenAccent, size: 18),
                label: const Text(
                  'Actualizar balance',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}

class CajaMnemotecnica extends StatelessWidget {
  final String fraseSemilla;

  const CajaMnemotecnica({super.key, required this.fraseSemilla});

  @override
  Widget build(BuildContext context) {
    final palabras = fraseSemilla.split(' ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.greenAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: palabras.asMap().entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: fraseSemilla));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Frase copiada al portapapeles'),
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, color: Colors.greenAccent, size: 18),
            label: const Text(
              'Copiar frase',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }
}
