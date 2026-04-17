import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dilexit/presentation/providers/wallet_provider.dart';
import 'package:Dilexit/presentation/screens/home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WalletProvider>().state;
    final theme = Theme.of(context);

    if (!state.isLoading && state.wallet != null) {
      Future.microtask(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 100,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'DILEXIT',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 48),
            if (state.isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                state.loadingMessage ?? 'Iniciando...',
                style: const TextStyle(color: Colors.white70),
              ),
            ] else if (state.wallet == null) ...[
              ElevatedButton(
                onPressed: () => context.read<WalletProvider>().createWallet(),
                child: const Text('Crear Wallet'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showImportDialog(context),
                child: const Text('Importar con Frase Semilla'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar Semilla'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tus 12 palabras...',
            ),
            validator: (v) => (v == null || v.trim().split(' ').length != 12) 
              ? 'Deben ser 12 palabras' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<WalletProvider>().importWallet(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}
