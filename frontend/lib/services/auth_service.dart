/// Authentication service wrapping Firebase Auth, Google Sign-In & Guest Session tracking.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Fetch Firebase ID token for secure API requests
  static Future<String?> getIdToken() async {
    if (_isFirebaseInitialized && FirebaseAuth.instance.currentUser != null) {
      return await FirebaseAuth.instance.currentUser!.getIdToken();
    }
    return null;
  }

  /// Sign in with 1-Click Google Provider
  static Future<AppUser> signInWithGoogle() async {
    if (_isFirebaseInitialized) {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In canceled by user.');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = AppUser.fromFirebase(userCred.user!);
      userNotifier.value = user;
      return user;
    }

    final user = const AppUser(
      uid: 'google_user_demo',
      email: 'developer@gmail.com',
      displayName: 'Google Developer',
    );
    userNotifier.value = user;
    return user;
  }

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
