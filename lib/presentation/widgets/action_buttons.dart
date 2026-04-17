import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onReceive;

  const ActionButtons({
    super.key,
    required this.onSend,
    required this.onReceive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.send_rounded,
            label: 'Enviar',
            onPressed: onSend,
          ),
          _ActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Recibir',
            onPressed: onReceive,
          ),
          _ActionButton(
            icon: Icons.shopping_cart_rounded,
            label: 'Comprar',
            onPressed: () {}, // TODO
            enabled: false,
          ),
          _ActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Swap',
            onPressed: () {}, // TODO
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled ? theme.colorScheme.primary : Colors.grey[700]!;

    return Column(
      children: [
        IconButton.filled(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, color: enabled ? Colors.black : Colors.grey[400]),
          style: IconButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
