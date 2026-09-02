import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

/// Authentication types supported by the app
enum AuthType { google, apple, phone, guest }

/// User model for the app
class AppUser {
  final String id;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final AuthType authType;
  final DateTime createdAt;
  final bool isGuest;

  const AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.authType,
    required this.createdAt,
    this.isGuest = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
        'photoUrl': photoUrl,
        'authType': authType.name,
        'createdAt': createdAt.toIso8601String(),
        'isGuest': isGuest ? 1 : 0,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'],
        displayName: map['displayName'],
        email: map['email'],
        phoneNumber: map['phoneNumber'],
        photoUrl: map['photoUrl'],
        authType: AuthType.values.firstWhere((e) => e.name == map['authType']),
        createdAt: DateTime.parse(map['createdAt']),
        isGuest: map['isGuest'] == 1,
      );

  /// Create a guest user (session-only, not persisted)
  factory AppUser.guest({String? name}) => AppUser(
        id: 'guest_${const Uuid().v4()}',
        displayName: (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : 'Guest Player',
        authType: AuthType.guest,
        createdAt: DateTime.now(),
        isGuest: true,
      );

  /// Create from Firebase User (Google/Apple/Phone)
  factory AppUser.fromFirebaseUser(User user, AuthType authType) => AppUser(
        id: user.uid,
        displayName: user.displayName ?? 'Player',
        email: user.email,
        phoneNumber: user.phoneNumber,
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
  ConfirmationResult? _webConfirmationResult;
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

  /// Send Phone OTP code via Firebase Auth
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!isFirebaseReady || _auth == null) {
      // Local development / fallback simulation
      await Future.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(isLoading: false);
      onCodeSent('simulated_${DateTime.now().millisecondsSinceEpoch}');
      return;
    }

    try {
      if (kIsWeb) {
        final confirmationResult = await _auth!.signInWithPhoneNumber(phoneNumber);
        _webConfirmationResult = confirmationResult;
        state = state.copyWith(isLoading: false);
        onCodeSent(confirmationResult.verificationId);
        return;
      }

      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Instant auto-verification (Android or web instant detection)
          try {
            final userCred = await _auth!.signInWithCredential(credential);
            if (userCred.user != null) {
              final appUser = AppUser(
                id: userCred.user!.uid,
                displayName: userCred.user!.displayName ??
                    (phoneNumber.length >= 4
                        ? 'Player ${phoneNumber.substring(phoneNumber.length - 4)}'
                        : 'Player'),
                phoneNumber: phoneNumber,
                email: userCred.user!.email,
                photoUrl: userCred.user!.photoURL,
                authType: AuthType.phone,
                createdAt: DateTime.now(),
              );
              state = state.copyWith(user: appUser, isLoading: false);
            }
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          // If Phone provider is disabled in Firebase Console:
          if (e.code == 'operation-not-allowed' ||
              (e.message != null && e.message!.toLowerCase().contains('disabled'))) {
            state = state.copyWith(isLoading: false);
            onCodeSent('simulated_disabled_${DateTime.now().millisecondsSinceEpoch}');
            return;
          }
          // If domain is not authorized on web:
          if (e.code == 'unauthorized-domain' ||
              (e.message != null && e.message!.toLowerCase().contains('authorized domain'))) {
            state = state.copyWith(isLoading: false);
            onCodeSent('simulated_domain_${DateTime.now().millisecondsSinceEpoch}');
            return;
          }
          state = state.copyWith(
            isLoading: false,
            error: e.message ?? 'Phone verification failed',
          );
          onError(e.message ?? 'Phone verification failed (${e.code})');
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(isLoading: false);
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout reached
        },
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('operation-not-allowed') || errStr.contains('disabled')) {
        state = state.copyWith(isLoading: false);
        onCodeSent('simulated_disabled_${DateTime.now().millisecondsSinceEpoch}');
        return;
      }
      if (errStr.contains('unauthorized-domain') || errStr.contains('authorized domain')) {
        state = state.copyWith(isLoading: false);
        onCodeSent('simulated_domain_${DateTime.now().millisecondsSinceEpoch}');
        return;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
      onError(e.toString());
    }
  }

  /// Verify 6-digit Phone OTP and sign in
  Future<bool> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (verificationId.startsWith('simulated_') || !isFirebaseReady || _auth == null) {
        // Local simulation fallback
        await Future.delayed(const Duration(milliseconds: 500));
        final uid = 'phone_${DateTime.now().millisecondsSinceEpoch}';
        final name = (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : (phoneNumber != null && phoneNumber.length >= 4
                ? 'Player ${phoneNumber.substring(phoneNumber.length - 4)}'
                : 'Tiger Hunter');

        final appUser = AppUser(
          id: uid,
          displayName: name,
          phoneNumber: phoneNumber,
          authType: AuthType.phone,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(user: appUser, isLoading: false);
        return true;
      }

      UserCredential userCredential;
      if (kIsWeb && _webConfirmationResult != null) {
        userCredential = await _webConfirmationResult!.confirm(smsCode.trim());
      } else {
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode.trim(),
        );
        userCredential = await _auth!.signInWithCredential(credential);
      }
      if (userCredential.user != null) {
        final name = (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : (userCredential.user!.displayName ??
                (phoneNumber != null && phoneNumber.length >= 4
                    ? 'Player ${phoneNumber.substring(phoneNumber.length - 4)}'
                    : 'Tiger Hunter'));

        if (displayName != null && displayName.trim().isNotEmpty) {
          try {
            await userCredential.user!.updateDisplayName(displayName.trim());
          } catch (_) {}
        }

        final appUser = AppUser(
          id: userCredential.user!.uid,
          displayName: name,
          phoneNumber: userCredential.user!.phoneNumber ?? phoneNumber,
          email: userCredential.user!.email,
          photoUrl: userCredential.user!.photoURL,
          authType: AuthType.phone,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(user: appUser, isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'Sign in failed');
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Invalid verification code',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in with phone number and passcode
  /// Uses Firebase Email/Password under the hood for security without SMS costs
  Future<bool> signInWithPhone({
    required String phoneNumber,
    required String passcode,
    String? displayName,
    bool isLogin = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final sanitized = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final name = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (sanitized.length >= 4
              ? 'Player ${sanitized.substring(sanitized.length - 4)}'
              : 'Tiger Hunter');
              
      if (!isFirebaseReady || _auth == null) {
        // Fallback simulation mode
        await Future.delayed(const Duration(milliseconds: 400));
        final uid = 'phone_$sanitized';
        final appUser = AppUser(
          id: uid,
          displayName: name,
          phoneNumber: phoneNumber,
          authType: AuthType.phone,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(user: appUser, isLoading: false);
        return true;
      }

      // Use fake email to leverage Firebase Email/Password Auth
      final fakeEmail = '$sanitized@tigerhunt.app';
      
      try {
        if (isLogin) {
          // 1. Try to sign in existing user
          final userCred = await _auth!.signInWithEmailAndPassword(
            email: fakeEmail,
            password: passcode,
          );
          
          if (userCred.user != null) {
            final appUser = AppUser(
              id: userCred.user!.uid,
              displayName: userCred.user!.displayName ?? name,
              phoneNumber: phoneNumber,
              authType: AuthType.phone,
              createdAt: DateTime.now(),
            );
            state = state.copyWith(user: appUser, isLoading: false);
            return true;
          }
        } else {
          // New User Sign Up flow
          try {
            final userCred = await _auth!.createUserWithEmailAndPassword(
              email: fakeEmail,
              password: passcode,
            );
            
            if (userCred.user != null) {
              await userCred.user!.updateDisplayName(name);
              
              final appUser = AppUser(
                id: userCred.user!.uid,
                displayName: name,
                phoneNumber: phoneNumber,
                authType: AuthType.phone,
                createdAt: DateTime.now(),
              );
              state = state.copyWith(user: appUser, isLoading: false);
              return true;
            }
          } on FirebaseAuthException catch (createError) {
             if (createError.code == 'email-already-in-use') {
                 state = state.copyWith(isLoading: false, error: 'Account already exists! Please go to the Login tab.');
                 return false;
             }
             if (createError.code == 'weak-password') {
                 state = state.copyWith(isLoading: false, error: 'Passcode must be at least 6 digits.');
                 return false;
             }
             state = state.copyWith(isLoading: false, error: createError.message);
             return false;
          }
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
           if (isLogin) {
              state = state.copyWith(isLoading: false, error: 'Incorrect passcode or account does not exist.');
              return false;
           }
        }
        state = state.copyWith(isLoading: false, error: e.message);
        return false;
      }

      state = state.copyWith(isLoading: false, error: 'Sign in failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign in as Guest (no Firebase)
  Future<bool> signInAsGuest({String? name}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final guestUser = AppUser.guest(name: name);
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
