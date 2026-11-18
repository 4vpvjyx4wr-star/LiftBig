import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../catalog/liftbig_catalog.dart';
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
    this.autoSyncDelay = defaultAutoSyncDelay,
  });

  final JournalRepository journal;
  final bool firebaseReady;
  final DayRemote Function(String uid)? remoteForUid;

  static const defaultAutoSyncDelay = Duration(seconds: 2);
  final Duration autoSyncDelay;
  static const _firebaseMissing =
      'Firebase is not configured. Add the files listed on this screen, then set kFirebaseEnabled to true.';
  static const _googlePhoneOnly =
      'Continue with Google works on iPhone. On this device, use email and password.';
  static const _googleNotConfigured =
      'Google sign-in failed. Check that Google is enabled for this Firebase project.';
  static const _googleChannel = MethodChannel('liftbig/google_sign_in');
  static const _applePhoneOnly =
      'Sign in with Apple works on iPhone. On this device, use email and password.';

  bool syncEnabled = false;
  bool busy = false;
  String? email;
  String? status;
  AccountReauthMethod reauthMethod = AccountReauthMethod.unsupported;
  StreamSubscription<User?>? _authSub;
  Timer? _autoSyncTimer;
  var _listening = false;
  var _rerunWhenIdle = false;
  String? _testUid;
  var _googleInitialized = false;
  Future<void>? _googleInit;

  bool get signedIn => email != null;

  /// Signs a test session in without Firebase Auth.
  @visibleForTesting
  void debugSignIn(String uid) {
    _testUid = uid;
    email = uid;
  }

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
    if (_testUid != null) {
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
    final uid = _currentUid();
    if (uid == null) {
      if (!automatic) {
        status =
            'Sign in before syncing. Until then the journal stays on this phone.';
        notifyListeners();
      }
      return;
    }
    if (busy) {
      _rerunWhenIdle = true;
      return;
    }
    busy = true;
    notifyListeners();
    try {
      var passes = 0;
      do {
        _rerunWhenIdle = false;
        passes += 1;
        final remote = remoteForUid?.call(uid) ?? FirestoreDayRemote(uid);
        final result = await JournalSync(
          journal: journal,
          remote: remote,
          premadeTemplateIds: await _premadeTemplateIds(),
        ).sync();
        final summary =
            'Synced. ${result.uploaded} uploaded, ${result.downloaded} downloaded.';
        status = result.skippedReason == null
            ? summary
            : '$summary ${result.skippedReason}';
      } while (_rerunWhenIdle && passes < 3);
    } catch (error) {
      status = 'Sync failed: $error';
    } finally {
      busy = false;
      notifyListeners();
      if (_rerunWhenIdle) {
        _rerunWhenIdle = false;
        _scheduleAutoSync();
      }
    }
  }

  String? _currentUid() {
    if (_testUid != null) return _testUid;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<Set<String>> _premadeTemplateIds() async {
    try {
      final catalog = await LiftBigCatalog.load();
      return {
        for (final plan in catalog.plans) plan.id,
        for (final workout in catalog.starterWorkouts) workout.id,
        for (final plan in catalog.plans)
          for (final workout in plan.workouts) workout.id,
      };
    } catch (_) {
      return const {};
    }
  }

  bool get _providerSignInOnThisPhone =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<AuthCredential> _googleAuthCredential() async {
    if (!_providerSignInOnThisPhone) {
      throw const _ProviderSignInException(_googlePhoneOnly);
    }
    final config = await _googleConfiguration();
    if (!googleSignInSchemeReady(config)) {
      throw const _ProviderSignInException(_googleNotConfigured);
    }
    await _ensureGoogleInitialized(googleServerClientId(config));
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

  Future<Map<Object?, Object?>?> _googleConfiguration() async {
    try {
      final result = await _googleChannel.invokeMethod<Object?>('configuration');
      if (result is Map) return Map<Object?, Object?>.from(result);
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _ensureGoogleInitialized(String? serverClientId) async {
    if (_googleInitialized) return;
    try {
      _googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
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

/// The iOS URL scheme is present, so `GIDSignIn` will not abort the process.
bool googleSignInSchemeReady(Map<Object?, Object?>? config) {
  return config?['ready'] == true;
}

/// Web client id from the local build, when one was compiled in.
String? googleServerClientId(Map<Object?, Object?>? config) {
  final server = config?['serverClientId'];
  if (server is! String || !server.contains('.apps.googleusercontent.com')) {
    return null;
  }
  return server;
}

class _ProviderSignInException implements Exception {
  const _ProviderSignInException(this.message);

  final String message;
}
