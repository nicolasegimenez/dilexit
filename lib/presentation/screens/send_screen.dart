import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';

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

  void _setMaxAmount(double balance) {
    setState(() {
      _amountController.text = balance.toStringAsFixed(8);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<WalletProvider>();
    final double balance = provider.state.wallet?.balanceInApt ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send APT'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card / Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Available balance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.toStringAsFixed(4)} APT',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Address Field
              TextFormField(
                controller: _addressController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Destination address',
                  hintText: '0x...',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                  helperText: 'Make sure the address is correct',
                  helperStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Address is required';
                  if (!v.startsWith('0x')) return 'Invalid address (must start with 0x)';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Amount Field
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount to send',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () => _setMaxAmount(balance),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('MAX'),
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  final amount = double.tryParse(v);
                  if (amount == null) return 'Invalid amount';
                  if (amount <= 0) return 'Amount must be greater than 0';
                  if (amount > balance) return 'Insufficient balance';
                  return null;
                },
              ),
              const SizedBox(height: 48),
              
              // Action Button
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
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Transaction sent successfully!'),
                                    ],
                                  ),
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
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: provider.state.isTransferring
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('PROCESSING...'),
                        ],
                      )
                    : const Text(
                        'CONFIRM SEND',
                        style: TextStyle(letterSpacing: 1.2),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
