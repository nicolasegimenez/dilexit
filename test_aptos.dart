import 'package:aptos/aptos.dart';

void main() {
  try {
    final mnemonic = AptosAccount.generateMnemonic();
    print('Mnemonic: $mnemonic');
    final account = AptosAccount.generateAccount(mnemonic);
    print('Private Key: ${account.toPrivateKeyObject().privateKeyHex}');
    print('Address: ${account.address}');
  } catch (e) {
    print('Error: $e');
  }
}
