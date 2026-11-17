/// How account deletion must confirm the current Firebase session.
enum AccountReauthMethod { password, google, apple, unsupported }

/// Maps a Firebase sign-in provider id to the matching reauth method.
AccountReauthMethod reauthMethodForProvider(String? providerId) {
  switch (providerId) {
    case 'password':
      return AccountReauthMethod.password;
    case 'google.com':
      return AccountReauthMethod.google;
    case 'apple.com':
      return AccountReauthMethod.apple;
    default:
      return AccountReauthMethod.unsupported;
  }
}

/// Prefers the provider that actually signed this session in.
///
/// [signInProvider] comes from the ID token. When that is missing, a single
/// linked provider is used. Mixed providers stay unsupported until the token
/// says which one was used.
AccountReauthMethod accountReauthMethod({
  required String? signInProvider,
  required List<String> providerIds,
}) {
  final fromToken = reauthMethodForProvider(signInProvider);
  if (fromToken != AccountReauthMethod.unsupported) return fromToken;
  final unique = providerIds.toSet();
  if (unique.length == 1) return reauthMethodForProvider(unique.single);
  return AccountReauthMethod.unsupported;
}
