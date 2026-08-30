import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

/// Authentication types supported by the app
enum AuthType { google, apple, guest }

/// User model for the app
class AppUser {
  final String id;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final AuthType authType;
  final DateTime createdAt;
  final bool isGuest;

  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.authType,
    required this.createdAt,
    this.isGuest = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'authType': authType.name,
        'createdAt': createdAt.toIso8601String(),
        'isGuest': isGuest ? 1 : 0,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'],
        displayName: map['displayName'],
        email: map['email'],
        photoUrl: map['photoUrl'],
        authType: AuthType.values.firstWhere((e) => e.name == map['authType']),
        createdAt: DateTime.parse(map['createdAt']),
        isGuest: map['isGuest'] == 1,
      );

  /// Create a guest user (session-only, not persisted)
  factory AppUser.guest() => AppUser(
        id: 'guest_${const Uuid().v4()}',
        displayName: 'Guest Player',
        authType: AuthType.guest,
        createdAt: DateTime.now(),
        isGuest: true,
      );

  /// Create from Firebase User (Google/Apple)
  factory AppUser.fromFirebaseUser(User user, AuthType authType) => AppUser(
        id: user.uid,
        displayName: user.displayName ?? 'Player',
        email: user.email,
        photoUrl: user.photoURL,
        authType: authType,
        createdAt: DateTime.now(),
      );
}

/// Authentication state
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  bool get isAuthenticated => user != null;
  bool get isGuest => user?.isGuest ?? false;
}

/// Authentication Service with Firebase
class AuthService extends StateNotifier<AuthState> {
  AuthService() : super(const AuthState());

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  bool _firebaseInitialized = false;

  /// Initialize Firebase dependencies (call after Firebase.initializeApp)
  void initializeFirebase() {
    if (!_firebaseInitialized) {
      try {
        // Check if Firebase is initialized
        Firebase.app();
        _auth = FirebaseAuth.instance;
        
        // Configure Google Sign-In with client ID for web
        // For web, the client ID must be set in index.html meta tag or passed here
        _googleSignIn = GoogleSignIn(
          // clientId: 'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com', // Set in web/index.html
          scopes: ['email', 'profile'],
        );
        _firebaseInitialized = true;
      } catch (_) {
        // Firebase not initialized (e.g., in tests)
        _firebaseInitialized = false;
      }
    }
  }

  /// Check if Firebase is available
  bool get isFirebaseReady => _firebaseInitialized && _auth != null;

  /// Stream of Google user changes (fires after the web button flow)
  Stream<GoogleSignInAccount?>? get googleUserStream =>
      isFirebaseReady ? _googleSignIn!.onCurrentUserChanged : null;

  /// Try to get the currently signed-in Google user without prompting (web button flow)
  Future<GoogleSignInAccount?> signInWithGoogleSilently() async {
    if (!isFirebaseReady) return null;
    try {
      return await _googleSignIn!.signInSilently();
    } catch (_) {
      return null;
    }
  }

  /// Complete sign-in with a Google account obtained via the web button flow
  Future<bool> handleGoogleUser(GoogleSignInAccount googleUser) async {
    if (!isFirebaseReady) {
      state = state.copyWith(isLoading: false, error: 'Firebase not initialized');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth!.signInWithCredential(credential);
      if (userCredential.user != null) {
        // Use GoogleSignInAccount's profile data (more reliable on web)
        final appUser = AppUser(
          id: userCredential.user!.uid,
          displayName: googleUser.displayName ?? userCredential.user!.displayName ?? 'Player',
          email: googleUser.email,
          photoUrl: googleUser.photoUrl ?? userCredential.user!.photoURL,
          authType: AuthType.google,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(user: appUser, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Failed to sign in');
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in with Google using Firebase
  Future<bool> signInWithGoogle() async {
    if (!isFirebaseReady) {
      state = state.copyWith(isLoading: false, error: 'Firebase not initialized');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        // User cancelled
        state = state.copyWith(isLoading: false, error: 'Sign in cancelled');
        return false;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth!.signInWithCredential(credential);
      if (userCredential.user != null) {
        // Use GoogleSignInAccount's profile data (more reliable)
        final appUser = AppUser(
          id: userCredential.user!.uid,
          displayName: googleUser.displayName ?? userCredential.user!.displayName ?? 'Player',
          email: googleUser.email,
          photoUrl: googleUser.photoUrl ?? userCredential.user!.photoURL,
          authType: AuthType.google,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(user: appUser, isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'Failed to sign in');
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in with Apple using Firebase
  Future<bool> signInWithApple() async {
    if (!isFirebaseReady) {
      state = state.copyWith(isLoading: false, error: 'Firebase not initialized');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth!.signInWithCredential(oauthCredential);
      if (userCredential.user != null) {
        // Apple only provides name on first sign-in, store it
        String displayName = userCredential.user!.displayName ?? 'Apple User';
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        }

        final appUser = AppUser(
          id: userCredential.user!.uid,
          displayName: displayName,
          email: userCredential.user!.email,
          photoUrl: userCredential.user!.photoURL,
          authType: AuthType.apple,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(user: appUser, isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'Failed to sign in');
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in as Guest (no Firebase)
  Future<bool> signInAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final guestUser = AppUser.guest();
      state = state.copyWith(user: guestUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      if (isFirebaseReady) {
        await Future.wait([
          _auth!.signOut(),
          _googleSignIn!.signOut(),
        ]);
      }
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Convert Firebase auth error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Account already exists with a different sign-in method';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'cancelled':
        return 'Sign in was cancelled.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }
}

/// Provider for AuthService
final authServiceProvider = StateNotifierProvider<AuthService, AuthState>((ref) {
  return AuthService();
});
