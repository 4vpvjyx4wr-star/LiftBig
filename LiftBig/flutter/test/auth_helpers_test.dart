import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/sync/account_reauth.dart';
import 'package:liftbig/sync/apple_nonce.dart';

void main() {
  test('sha256 nonce is the hex digest of the raw nonce', () {
    expect(
      sha256Nonce('hello'),
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
    );
  });

  test('raw nonce stays in the Apple charset', () {
    final nonce = randomRawNonce(length: 128, random: Random(1));
    expect(nonce, hasLength(128));
    expect(
      randomRawNonce(length: 32, random: Random(4)),
      randomRawNonce(length: 32, random: Random(4)),
    );
    for (final char in nonce.split('')) {
      expect(appleNonceCharset.contains(char), isTrue);
    }
  });

  test('reauth follows the provider that signed the session in', () {
    expect(reauthMethodForProvider('password'), AccountReauthMethod.password);
    expect(reauthMethodForProvider('google.com'), AccountReauthMethod.google);
    expect(reauthMethodForProvider('apple.com'), AccountReauthMethod.apple);
    expect(reauthMethodForProvider(null), AccountReauthMethod.unsupported);
    expect(
      reauthMethodForProvider('facebook.com'),
      AccountReauthMethod.unsupported,
    );

    expect(
      accountReauthMethod(
        signInProvider: 'apple.com',
        providerIds: ['password', 'apple.com'],
      ),
      AccountReauthMethod.apple,
    );
    expect(
      accountReauthMethod(
        signInProvider: 'google.com',
        providerIds: ['password', 'google.com'],
      ),
      AccountReauthMethod.google,
    );
    expect(
      accountReauthMethod(
        signInProvider: null,
        providerIds: ['google.com'],
      ),
      AccountReauthMethod.google,
    );
    expect(
      accountReauthMethod(
        signInProvider: null,
        providerIds: ['password', 'google.com'],
      ),
      AccountReauthMethod.unsupported,
    );
  });
}
