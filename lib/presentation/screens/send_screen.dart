import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dilexit/presentation/providers/wallet_provider.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Enviar APT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: 'Dirección de destino',
                  hintText: '0x...',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  hintText: '0.00',
                  suffixText: 'APT',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: provider.state.isTransferring
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            final amount = double.parse(_amountController.text.trim());
                            final octas = BigInt.from((amount * 100000000).toInt());
                            
                            final tx = await provider.transferApt(
                              _addressController.text.trim(),
                              octas,
                            );

                            if (tx != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Transacción Enviada!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: provider.state.isTransferring
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar Envío'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
