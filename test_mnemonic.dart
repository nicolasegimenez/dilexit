import 'package:aptos/aptos.dart';

void main() {
  try {
    final mnemonic = AptosAccount.generateMnemonic();
    print('Mnemonic: $mnemonic');
  } catch (e) {
    print('Error: $e');
  }
}
