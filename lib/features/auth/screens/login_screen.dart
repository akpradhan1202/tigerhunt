import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_button.dart'
    if (dart.library.html) '../../../core/services/google_button_web.dart'
    as google_button;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  StreamSubscription? _googleUserSub;
  Widget? _webGoogleButton;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    _setupWebGoogleSignIn();
  }

  void _setupWebGoogleSignIn() {
    if (!kIsWeb) return;
    final auth = ref.read(authServiceProvider.notifier);
    if (!auth.isFirebaseReady) return;

    // Render the official Google button once (web only)
    _webGoogleButton = google_button.buildGoogleSignInButton();

    // Listen for sign-in completion via onCurrentUserChanged stream
    _googleUserSub = auth.googleUserStream?.listen((user) async {
      if (user != null && mounted) {
        final success = await auth.handleGoogleUser(user);
        if (success && mounted) {
          context.go('/play');
        }
      }
    });

    // Fallback: periodically try signInSilently to catch the user
    // after they complete the GIS flow (button click)
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || ref.read(authServiceProvider).isAuthenticated) {
        timer.cancel();
        return;
      }
      _trySignInSilently(auth);
    });
  }

  Future<void> _trySignInSilently(AuthService auth) async {
    try {
      final user = await auth.signInWithGoogleSilently();
      if (user != null && mounted) {
        final success = await auth.handleGoogleUser(user);
        if (success && mounted) {
          context.go('/play');
        }
      }
    } catch (_) {
      // Ignore - will retry
    }
  }

  @override
  void dispose() {
    _googleUserSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGuestLogin() async {
    final authService = ref.read(authServiceProvider.notifier);
    final success = await authService.signInAsGuest();

    if (success && mounted) {
      context.go('/play');
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authService = ref.read(authServiceProvider.notifier);
    final success = await authService.signInWithGoogle();

    if (success && mounted) {
      context.go('/play');
    } else if (mounted && ref.read(authServiceProvider).error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authServiceProvider).error!),
          backgroundColor: AppTheme.terracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    final authService = ref.read(authServiceProvider.notifier);
    final success = await authService.signInWithApple();

    if (success && mounted) {
      context.go('/play');
    } else if (mounted && ref.read(authServiceProvider).error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authServiceProvider).error!),
          backgroundColor: AppTheme.terracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo section
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Tiger icon
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.tigerOrange.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('🐯', style: TextStyle(fontSize: 50)),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Game title
                            const Text(
                              'TigerHunt',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Bagh-Chal',
                              style: TextStyle(
                                color: AppTheme.greenAccent,
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'Ancient Strategy Game',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Login card
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildLoginCard(isLoading),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Footer
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'By continuing, you agree to our Terms of Service',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.tigerOrange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Text(
            'Welcome, Player!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to track your progress',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),

          // Google login (official button on web, custom button on mobile)
          if (_webGoogleButton != null)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _webGoogleButton!,
              ),
            )
          else
            _buildLoginButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata_rounded,
              iconColor: Colors.red,
              backgroundColor: Colors.white,
              textColor: AppTheme.charcoal,
              onTap: isLoading ? null : _handleGoogleLogin,
            ),

          const SizedBox(height: 12),

          // Apple login
          _buildLoginButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            iconColor: Colors.white,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            onTap: isLoading ? null : _handleAppleLogin,
          ),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
              ),
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
            ],
          ),

          const SizedBox(height: 20),

          // Guest play - always enabled
          _buildLoginButton(
            label: 'Play as Guest',
            icon: Icons.person_outline,
            iconColor: Colors.white,
            backgroundColor: AppTheme.greenAccent,
            textColor: Colors.white,
            onTap: isLoading ? null : _handleGuestLogin,
          ),

          const SizedBox(height: 8),

          Text(
            'Guest progress won\'t be saved online',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
