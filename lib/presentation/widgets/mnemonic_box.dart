import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MnemonicBox extends StatelessWidget {
  final String fraseSemilla;

  const MnemonicBox({super.key, required this.fraseSemilla});

  @override
  Widget build(BuildContext context) {
    final palabras = fraseSemilla.split(' ');
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: theme.colorScheme.primary, width: 2),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
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
                const SnackBar(content: Text('Frase copiada al portapapeles')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar frase'),
          ),
        ],
      ),
    );
  }
}
