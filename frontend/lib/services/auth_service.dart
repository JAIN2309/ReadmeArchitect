/// Authentication service wrapping Firebase Auth, Google Sign-In & Guest Session tracking.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName ??
          user.email?.split('@').first ??
          'Developer',
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }
}

class AuthService {
  AuthService._();

  static final ValueNotifier<AppUser?> userNotifier =
      ValueNotifier<AppUser?>(null);

  // ── Firebase Initialization ───────────────────────────────────────────────

  /// Ensure Firebase is initialized. Safe to call multiple times.
  static Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  static bool get _isReady => Firebase.apps.isNotEmpty;

  /// Initialize Firebase Auth state listener. Must be called after Firebase.initializeApp().
  static Future<void> initialize() async {
    try {
      await _ensureFirebase();
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        userNotifier.value = user != null ? AppUser.fromFirebase(user) : null;
      });
      // Restore persistent session (Firebase persists login across refreshes)
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        userNotifier.value = AppUser.fromFirebase(current);
      }
    } catch (e) {
      if (kDebugMode) print('[AuthService] initialize error: $e');
    }
  }

  static AppUser? get currentUser => userNotifier.value;
  static bool get isLoggedIn => userNotifier.value != null;
  static bool get isFirebaseReady => _isReady;

  // ── ID Token for API auth ─────────────────────────────────────────────────

  static Future<String?> getIdToken() async {
    if (_isReady && FirebaseAuth.instance.currentUser != null) {
      return await FirebaseAuth.instance.currentUser!.getIdToken();
    }
    return null;
  }

  // ── Sign-In Methods ───────────────────────────────────────────────────────

  /// Google Sign-In — shows account picker popup on Web, uses plugin on native.
  static Future<AppUser> signInWithGoogle() async {
    // Always ensure Firebase is initialized before signing in
    await _ensureFirebase();

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});

      final userCred =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);
      final user = AppUser.fromFirebase(userCred.user!);
      userNotifier.value = user;
      return user;
    } else {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In cancelled.');
      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = AppUser.fromFirebase(userCred.user!);
      userNotifier.value = user;
      return user;
    }
  }

  /// Sign in with Email and Password.
  static Future<AppUser> signInWithEmail(String email, String password) async {
    await _ensureFirebase();
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = AppUser.fromFirebase(cred.user!);
    userNotifier.value = user;
    return user;
  }

  /// Register new user with Email and Password.
  static Future<AppUser> signUpWithEmail(String email, String password) async {
    await _ensureFirebase();
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = AppUser.fromFirebase(cred.user!);
    userNotifier.value = user;
    return user;
  }

  /// Anonymous Guest Session.
  static Future<AppUser> signInAsGuest() async {
    await _ensureFirebase();
    final cred = await FirebaseAuth.instance.signInAnonymously();
    final user = AppUser.fromFirebase(cred.user!);
    userNotifier.value = user;
    return user;
  }

  /// Sign out from Firebase and clear local session.
  static Future<void> signOut() async {
    if (_isReady) {
      await FirebaseAuth.instance.signOut();
    }
    userNotifier.value = null;
  }
}
