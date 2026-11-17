import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../firebase_options.dart';
import '../journal/journal_repository.dart';
import 'account_reauth.dart';
import 'apple_nonce.dart';
import 'day_remote.dart';
import 'firestore_day_remote.dart';
import 'journal_sync.dart';

/// Sign-in and the settings switch. Sync runs when the switch is on and a
/// user is signed in: at launch, on resume, and shortly after a local write.
class SyncController extends ChangeNotifier with WidgetsBindingObserver {
  SyncController({
    required this.journal,
    required this.firebaseReady,
    this.remoteForUid,
  });

  final JournalRepository journal;
  final bool firebaseReady;
  final DayRemote Function(String uid)? remoteForUid;

  static const autoSyncDelay = Duration(seconds: 2);
  static const _firebaseMissing =
      'Firebase is not configured. Add the files listed on this screen, then set kFirebaseEnabled to true.';
  static const _googlePhoneOnly =
      'Continue with Google works on iPhone. On this device, use email and password.';
  static const _applePhoneOnly =
      'Sign in with Apple works on iPhone. On this device, use email and password.';
  static const _googleClientMissing =
      'Google sign-in needs a client id in GoogleService-Info.plist. Re-download that file from the Firebase console after enabling Google.';

  bool syncEnabled = false;
  bool busy = false;
  String? email;
  String? status;
  AccountReauthMethod reauthMethod = AccountReauthMethod.unsupported;
  StreamSubscription<User?>? _authSub;
  Timer? _autoSyncTimer;
  var _listening = false;
  var _googleInitialized = false;
  Future<void>? _googleInit;

  bool get signedIn => email != null;

  bool get passwordAccount => reauthMethod == AccountReauthMethod.password;

  Future<void> load() async {
    syncEnabled = await journal.isSyncEnabled();
    if (!_listening) {
      journal.addLocalWriteListener(_scheduleAutoSync);
      WidgetsBinding.instance.addObserver(this);
      _listening = true;
    }
    if (!firebaseReady) {
      status =
          'Sync is off. The journal stays on this phone until Firebase config is added.';
      notifyListeners();
      return;
    }
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _applyUser(user);
      if (user != null && syncEnabled) {
        await syncNow(automatic: true);
      }
    });
    notifyListeners();
  }

  Future<void> _applyUser(User? user) async {
    if (user == null) {
      email = null;
      reauthMethod = AccountReauthMethod.unsupported;
      notifyListeners();
      return;
    }
    email = user.email ?? user.uid;
    reauthMethod = accountReauthMethod(
      signInProvider: null,
      providerIds: [for (final info in user.providerData) info.providerId],
    );
    notifyListeners();
    reauthMethod = await _reauthMethodFor(user);
    if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;
    email = FirebaseAuth.instance.currentUser?.email ?? user.email ?? user.uid;
    notifyListeners();
  }

  Future<AccountReauthMethod> _reauthMethodFor(User user) async {
    String? signInProvider;
    try {
      signInProvider = (await user.getIdTokenResult()).signInProvider;
    } catch (_) {
      signInProvider = null;
    }
    return accountReauthMethod(
      signInProvider: signInProvider,
      providerIds: [for (final info in user.providerData) info.providerId],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncNow(automatic: true));
    }
  }

  void _scheduleAutoSync() {
    if (!firebaseReady || !syncEnabled || !signedIn) return;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(autoSyncDelay, () {
      unawaited(syncNow(automatic: true));
    });
  }

  Future<void> setEnabled(bool value) async {
    syncEnabled = value;
    await journal.setSyncEnabled(value);
    if (!value) {
      _autoSyncTimer?.cancel();
      status = 'Sync is off. Nothing is uploaded.';
      notifyListeners();
      return;
    }
    notifyListeners();
    if (signedIn) await syncNow();
  }

  Future<String?> signIn({
    required String emailAddress,
    required String password,
    required bool createAccount,
  }) async {
    if (!firebaseReady) return _firebaseMissing;
    try {
      final auth = FirebaseAuth.instance;
      final trimmed = emailAddress.trim();
      if (createAccount) {
        await auth.createUserWithEmailAndPassword(
          email: trimmed,
          password: password,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: trimmed,
          password: password,
        );
      }
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? error.code;
    }
  }

  /// Google sign-in on iPhone. Other platforms return a message.
  Future<String?> signInWithGoogle() {
    return _signInWithProvider(_googleAuthCredential, _googleSignInMessage);
  }

  /// Sign in with Apple on iPhone. Other platforms return a message.
  Future<String?> signInWithApple() {
    return _signInWithProvider(_appleAuthCredential, _appleSignInMessage);
  }

  Future<String?> _signInWithProvider(
    Future<AuthCredential> Function() credential,
    String Function(Object error) message,
  ) async {
    if (!firebaseReady) return _firebaseMissing;
    try {
      await FirebaseAuth.instance.signInWithCredential(await credential());
      return null;
    } catch (error) {
      return message(error);
    }
  }

  Future<String?> sendPasswordReset(String emailAddress) async {
    if (!firebaseReady) return _firebaseMissing;
    final trimmed = emailAddress.trim();
    if (trimmed.isEmpty) return 'Enter the email for this account.';
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed);
      status = 'Password reset email sent.';
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return error.message ?? error.code;
    }
  }

  /// Reauthenticates with the provider that signed this session in, deletes
  /// this user's cloud documents, then the Auth user. The journal on this
  /// phone is left in place. [password] is used only for email accounts.
  Future<String?> deleteAccount(String password) async {
    if (!firebaseReady) return _firebaseMissing;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Sign in before deleting the account.';
    final method = await _reauthMethodFor(user);
    reauthMethod = method;
    if (method == AccountReauthMethod.password) {
      final address = user.email;
      if (address == null || address.isEmpty) {
        return 'This account has no email address.';
      }
      if (password.isEmpty) return 'Enter your password to delete the account.';
    } else if (method == AccountReauthMethod.unsupported) {
      return 'Sign in again with email, Google, or Apple before deleting the account.';
    }
    busy = true;
    notifyListeners();
    try {
      final credential = await _credentialFor(user, method, password);
      await user.reauthenticateWithCredential(credential);
      final remote = remoteForUid?.call(user.uid) ?? FirestoreDayRemote(user.uid);
      await remote.deleteAll();
      await user.delete();
      await _signOutGoogle();
      email = null;
      reauthMethod = AccountReauthMethod.unsupported;
      status =
          'The cloud copy and sign-in are removed. The journal on this phone stays.';
      return null;
    } on _ProviderSignInException catch (error) {
      return error.message;
    } on GoogleSignInException catch (error) {
      return _googleSignInMessage(error);
    } on SignInWithAppleAuthorizationException catch (error) {
      return _appleSignInMessage(error);
    } on SignInWithAppleNotSupportedException catch (error) {
      return _appleSignInMessage(error);
    } on FirebaseAuthException catch (error) {
      return error.message ?? error.code;
    } catch (error) {
      return 'Could not delete the account. $error';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<AuthCredential> _credentialFor(
    User user,
    AccountReauthMethod method,
    String password,
  ) {
    switch (method) {
      case AccountReauthMethod.password:
        return Future.value(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      case AccountReauthMethod.google:
        return _googleAuthCredential();
      case AccountReauthMethod.apple:
        return _appleAuthCredential();
      case AccountReauthMethod.unsupported:
        throw const _ProviderSignInException(
          'Sign in again with email, Google, or Apple before deleting the account.',
        );
    }
  }

  Future<void> signOut() async {
    if (!firebaseReady) return;
    await FirebaseAuth.instance.signOut();
    await _signOutGoogle();
    email = null;
    reauthMethod = AccountReauthMethod.unsupported;
    status = 'Signed out. The journal is still on this phone.';
    notifyListeners();
  }

  Future<void> syncNow({bool automatic = false}) async {
    if (!firebaseReady || !syncEnabled) {
      if (!automatic) {
        status = !firebaseReady
            ? 'Sync did nothing. Firebase config is not in the app yet.'
            : 'Sync is off.';
        notifyListeners();
      }
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!automatic) {
        status =
            'Sign in before syncing. Until then the journal stays on this phone.';
        notifyListeners();
      }
      return;
    }
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      final remote = remoteForUid?.call(user.uid) ?? FirestoreDayRemote(user.uid);
      final result = await JournalSync(journal: journal, remote: remote).sync();
      status =
          'Synced. ${result.uploaded} uploaded, ${result.downloaded} downloaded.';
    } catch (error) {
      status = 'Sync failed: $error';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  bool get _providerSignInOnThisPhone =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<AuthCredential> _googleAuthCredential() async {
    if (!_providerSignInOnThisPhone) {
      throw const _ProviderSignInException(_googlePhoneOnly);
    }
    final clientId = DefaultFirebaseOptions.ios.iosClientId;
    if (clientId == null || clientId.isEmpty) {
      throw const _ProviderSignInException(_googleClientMissing);
    }
    await _ensureGoogleInitialized(clientId);
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const _ProviderSignInException(_googlePhoneOnly);
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const _ProviderSignInException(
        'Google did not return an identity token.',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  Future<void> _ensureGoogleInitialized(String clientId) async {
    if (_googleInitialized) return;
    try {
      _googleInit ??= GoogleSignIn.instance.initialize(clientId: clientId);
      await _googleInit;
      _googleInitialized = true;
    } catch (_) {
      _googleInit = null;
      rethrow;
    }
  }

  Future<AuthCredential> _appleAuthCredential() async {
    if (!_providerSignInOnThisPhone) {
      throw const _ProviderSignInException(_applePhoneOnly);
    }
    final rawNonce = randomRawNonce();
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: sha256Nonce(rawNonce),
    );
    final idToken = apple.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw const _ProviderSignInException(
        'Apple did not return an identity token.',
      );
    }
    return OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: apple.authorizationCode,
    );
  }

  Future<void> _signOutGoogle() async {
    if (!_googleInitialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } on GoogleSignInException {
      return;
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  String _googleSignInMessage(Object error) {
    if (error is _ProviderSignInException) return error.message;
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return 'Google sign-in was canceled.';
      }
      return 'Google sign-in failed. Check that Google is enabled for this Firebase project.';
    }
    if (error is FirebaseAuthException) return error.message ?? error.code;
    if (error is MissingPluginException) return _googlePhoneOnly;
    return 'Google sign-in failed.';
  }

  String _appleSignInMessage(Object error) {
    if (error is _ProviderSignInException) return error.message;
    if (error is SignInWithAppleAuthorizationException) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return 'Sign in with Apple was canceled.';
      }
      return 'Sign in with Apple failed. Confirm the App ID has Sign in with Apple enabled.';
    }
    if (error is SignInWithAppleNotSupportedException) return _applePhoneOnly;
    if (error is FirebaseAuthException) return error.message ?? error.code;
    if (error is MissingPluginException) return _applePhoneOnly;
    return 'Sign in with Apple failed.';
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    if (_listening) {
      journal.removeLocalWriteListener(_scheduleAutoSync);
      WidgetsBinding.instance.removeObserver(this);
      _listening = false;
    }
    unawaited(_authSub?.cancel());
    super.dispose();
  }
}

class _ProviderSignInException implements Exception {
  const _ProviderSignInException(this.message);

  final String message;
}
