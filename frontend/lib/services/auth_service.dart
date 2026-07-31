/// Authentication service wrapping Firebase Auth & Guest Mode session tracking.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      displayName: user.displayName ?? user.email?.split('@').first ?? 'Developer',
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }
}

class AuthService {
  AuthService._();

  static final ValueNotifier<AppUser?> userNotifier = ValueNotifier<AppUser?>(null);

  static bool _isFirebaseInitialized = false;

  /// Initialize Firebase Auth listener.
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseInitialized = true;
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          if (user != null) {
            userNotifier.value = AppUser.fromFirebase(user);
          } else {
            userNotifier.value = null;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Firebase Auth initialization skipped: $e');
    }
  }

  static AppUser? get currentUser => userNotifier.value;
  static bool get isLoggedIn => userNotifier.value != null;

  /// Sign in with Email and Password
  static Future<AppUser> signInWithEmail(String email, String password) async {
    if (_isFirebaseInitialized) {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = AppUser.fromFirebase(cred.user!);
      userNotifier.value = user;
      return user;
    }
    // Session fallback for demo
    final user = AppUser(
      uid: 'user_${email.hashCode}',
      email: email,
      displayName: email.split('@').first,
    );
    userNotifier.value = user;
    return user;
  }

  /// Register new user with Email and Password
  static Future<AppUser> signUpWithEmail(String email, String password) async {
    if (_isFirebaseInitialized) {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = AppUser.fromFirebase(cred.user!);
      userNotifier.value = user;
      return user;
    }

    final user = AppUser(
      uid: 'user_${email.hashCode}',
      email: email,
      displayName: email.split('@').first,
    );
    userNotifier.value = user;
    return user;
  }

  /// Guest Sign-In (Anonymous Session)
  static Future<AppUser> signInAsGuest() async {
    if (_isFirebaseInitialized) {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      final user = AppUser.fromFirebase(cred.user!);
      userNotifier.value = user;
      return user;
    }

    final user = const AppUser(
      uid: 'guest_session',
      displayName: 'Guest Developer',
      isAnonymous: true,
    );
    userNotifier.value = user;
    return user;
  }

  /// Sign Out
  static Future<void> signOut() async {
    if (_isFirebaseInitialized) {
      await FirebaseAuth.instance.signOut();
    }
    userNotifier.value = null;
  }
}
