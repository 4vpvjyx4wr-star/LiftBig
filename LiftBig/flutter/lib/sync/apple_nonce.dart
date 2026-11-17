import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Charset from the Firebase Apple sign-in sample. The raw nonce is hashed
/// before it is sent to Apple; Firebase receives the raw value.
const appleNonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

/// Cryptographically secure raw nonce for Sign in with Apple.
String randomRawNonce({int length = 32, Random? random}) {
  final source = random ?? Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(appleNonceCharset[source.nextInt(appleNonceCharset.length)]);
  }
  return buffer.toString();
}

/// Lowercase hex SHA-256 of [rawNonce]. Apple receives this; Firebase gets the raw nonce.
String sha256Nonce(String rawNonce) {
  return sha256.convert(utf8.encode(rawNonce)).toString();
}
