import 'package:flutter_test/flutter_test.dart';
import 'package:aptos/aptos.dart';

void main() {
  test('generate mnemonic', () {
    final mnemonic = AptosAccount.generateMnemonic();
    print('Mnemonic: $mnemonic');
    final account = AptosAccount.generateAccount(mnemonic);
    print('Address: ${account.address}');
    print('Private Key: ${account.toPrivateKeyObject().privateKeyHex}');
  });
}
