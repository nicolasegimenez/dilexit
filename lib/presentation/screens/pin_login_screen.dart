import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dilexit/presentation/providers/auth_provider.dart';
import 'package:dilexit/presentation/providers/wallet_provider.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
        _hasError = false;
      });
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _hasError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await context.read<AuthProvider>().unlock(_pin);
    if (!success) {
      HapticFeedback.heavyImpact();
      setState(() => _hasError = true);
      await _shakeController.forward(from: 0);
      setState(() => _pin = '');
    }
  }

  void _showDeleteWalletDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Reset App', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete your wallet? This will erase all data and you will need your seed phrase to recover your funds.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<WalletProvider>().logout();
              if (context.mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              const Text(
                'Enter PIN',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              
              // PIN Dots
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _hasError ? (12 - (_shakeAnimation.value % 24)).abs() - 12 : 0, 
                      0
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled 
                            ? (_hasError ? Colors.redAccent : theme.colorScheme.primary) 
                            : Colors.white10,
                      ),
                    );
                  }),
                ),
              ),
              
              if (_hasError)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Incorrect PIN', style: TextStyle(color: Colors.redAccent)),
                ),
              
              const Spacer(),
              
              // Numpad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int j = 1; j <= 3; j++)
                          _NumpadButton(
                          text: '${i * 3 + j}',
                          onPressed: () => _onDigitPressed('${i * 3 + j}'),
                          ),
                        ],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NumpadButton(
                          icon: Icons.delete_outline,
                          onPressed: _showDeleteWalletDialog,
                          isTransparent: true,
                        ),
                        _NumpadButton(
                          text: '0',
                          onPressed: () => _onDigitPressed('0'),
                        ),
                        _NumpadButton(
                          icon: Icons.backspace_outlined,
                          onPressed: _onDeletePressed,
                          isTransparent: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isTransparent;

  const _NumpadButton({
    this.text,
    this.icon,
    required this.onPressed,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: isTransparent ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: Colors.white, size: 28)
                  : Text(
                      text!,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
