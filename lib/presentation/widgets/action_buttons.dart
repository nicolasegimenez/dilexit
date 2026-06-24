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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Enviar',
            onPressed: onSend,
          ),
          _ActionButton(
            icon: Icons.arrow_downward_rounded,
            label: 'Recibir',
            onPressed: onReceive,
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
    final color = enabled
        ? theme.colorScheme.primary
        : Colors.white.withValues(alpha: 0.3);
    final bgColor = enabled
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.05);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(24),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: enabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
