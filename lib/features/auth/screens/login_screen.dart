import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/google_button.dart'
    if (dart.library.html) '../../../core/services/google_button_web.dart'
    as google_button;
import '../../../core/theme/app_theme.dart';
import '../widgets/phone_login_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? name;

  const LoginScreen({super.key, this.name});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late final TextEditingController _guestNameController;
  StreamSubscription? _googleUserSub;
  Widget? _webGoogleButton;

  static const _randomNicknames = [
    'HimalayanHunter',
    'TigerClaw',
    'SnowLeopard',
    'MountainGoat',
    'TigerFang',
    'BraveKid',
    'SherpaTactician',
    'ApexPredator',
    'GoldenGoat',
    'ChitwanKing',
    'ValleyProtector',
    'ForestStalker',
  ];

  @override
  void initState() {
    super.initState();
    _guestNameController = TextEditingController(text: widget.name ?? '');
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _setupWebGoogleSignIn();
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != oldWidget.name && widget.name != null) {
      _guestNameController.text = widget.name!;
    }
  }

  void _setupWebGoogleSignIn() {
    if (!kIsWeb) return;
    final auth = ref.read(authServiceProvider.notifier);
    if (!auth.isFirebaseReady) return;

    // Render official Google button once for web
    _webGoogleButton = google_button.buildGoogleSignInButton();

    _googleUserSub = auth.googleUserStream?.listen((user) async {
      if (user != null && mounted) {
        final success = await auth.handleGoogleUser(user);
        if (success && mounted) {
          context.go('/play');
        }
      }
    });

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
    } catch (_) {}
  }

  @override
  void dispose() {
    _googleUserSub?.cancel();
    _guestNameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _rollRandomNickname() {
    final rand = _randomNicknames[Random().nextInt(_randomNicknames.length)];
    setState(() => _guestNameController.text = rand);
  }

  Future<void> _handleGuestLogin([String? name]) async {
    final authService = ref.read(authServiceProvider.notifier);
    final guestName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (_guestNameController.text.trim().isNotEmpty
            ? _guestNameController.text.trim()
            : widget.name);
    final success = await authService.signInAsGuest(name: guestName);

    if (success && mounted) {
      try {
        context.go('/play');
      } catch (_) {}
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

  void _openPhoneLogin() {
    PhoneLoginSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D131A),
      body: Stack(
        children: [
          // Ambient background glow circles
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.tigerOrange.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.greenAccent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 880) {
                            return _buildDesktopLayout(isLoading);
                          } else {
                            return _buildMobileLayout(isLoading);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.tigerOrange),
              ),
            ),
        ],
      ),
    );
  }

  // ================= DESKTOP TWO-COLUMN LAYOUT =================

  Widget _buildDesktopLayout(bool isLoading) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column: Vibrant Hero Showcase
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: _buildHeroShowcase(isCompact: false),
          ),
        ),

        // Right Column: Sign In Card
        Expanded(
          flex: 5,
          child: _buildLoginCard(isLoading),
        ),
      ],
    );
  }

  // ================= MOBILE SINGLE-COLUMN LAYOUT =================

  Widget _buildMobileLayout(bool isLoading) {
    return Column(
      children: [
        _buildHeroShowcase(isCompact: true),
        const SizedBox(height: 28),
        _buildLoginCard(isLoading),
        const SizedBox(height: 20),
        _buildFooter(),
      ],
    );
  }

  // ================= HERO SHOWCASE =================

  Widget _buildHeroShowcase({required bool isCompact}) {
    return Column(
      crossAxisAlignment:
          isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Category / Heritage Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.tigerOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.tigerOrange.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🐯', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text(
                'ANCIENT HIMALAYAN STRATEGY • 2 PLAYERS',
                style: TextStyle(
                  color: AppTheme.tigerOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title with Gradient Effect
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFB347), Color(0xFFFFCC33), Color(0xFFE87A1E)],
          ).createShader(bounds),
          child: Text(
            'TigerHunt',
            textAlign: isCompact ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 36 : 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Catchphrase Tagline
        Text(
          '4 fierce Tigers hunt. 20 agile Goats surround. Outsmart your opponent in real-time tactical battles.',
          textAlign: isCompact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: isCompact ? 14 : 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Interactive / Stylized Mini Board Preview
        _buildBoardShowcaseCard(isCompact: isCompact),
      ],
    );
  }

  Widget _buildBoardShowcaseCard({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini board illustration
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF1B232D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.tigerOrange.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Diagonal cross lines
                Center(
                  child: CustomPaint(
                    size: const Size(60, 60),
                    painter: _MiniBoardPainter(),
                  ),
                ),
                // 4 Tigers at corners
                const Positioned(top: 4, left: 6, child: Text('🐯', style: TextStyle(fontSize: 14))),
                const Positioned(top: 4, right: 6, child: Text('🐯', style: TextStyle(fontSize: 14))),
                const Positioned(bottom: 4, left: 6, child: Text('🐯', style: TextStyle(fontSize: 14))),
                const Positioned(bottom: 4, right: 6, child: Text('🐯', style: TextStyle(fontSize: 14))),
                // Goats in center
                const Center(child: Text('🐐', style: TextStyle(fontSize: 18))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.greenAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Asymmetric Warfare',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tigers leap & capture. Goats trap & immobilize. Every move counts.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= LOGIN CARD =================

  Widget _buildLoginCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tigerOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎮', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join the Hunt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Play with friends & track your rating',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Mobile Phone Login (Prominent & High Priority)
          _buildActionButton(
            label: 'Continue with Mobile Number',
            subtitle: 'Instant SMS OTP verification',
            icon: Icons.phone_android_rounded,
            iconColor: Colors.white,
            gradient: const LinearGradient(
              colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
            ),
            textColor: Colors.white,
            onTap: isLoading ? null : _openPhoneLogin,
          ),
          const SizedBox(height: 12),

          // 2. Google Login
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

          // 3. Apple Login
          _buildLoginButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            iconColor: Colors.white,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            onTap: isLoading ? null : _handleAppleLogin,
          ),

          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR QUICK PLAY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
            ],
          ),
          const SizedBox(height: 20),

          // Guest nickname input with dice button
          TextField(
            controller: _guestNameController,
            enabled: !isLoading,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Guest name (optional)',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: const Text('🎲', style: TextStyle(fontSize: 18)),
                tooltip: 'Roll random nickname',
                onPressed: _rollRandomNickname,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppTheme.greenAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Guest play button
          ElevatedButton.icon(
            onPressed: isLoading ? null : () => _handleGuestLogin(),
            icon: const Icon(Icons.flash_on, size: 18, color: Colors.white),
            label: const Text(
              'Play as Guest',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'Guest mode is instant • Create an account to add friends and play online',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Gradient gradient,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B09B).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: backgroundColor == Colors.black
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'TigerHunt • Bagh-Chal Ancient Heritage Strategy\nTerms of Service & Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 11,
        height: 1.4,
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // Outer box
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Diagonals
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Diamond
    final midX = size.width / 2;
    final midY = size.height / 2;
    final path = Path()
      ..moveTo(midX, 0)
      ..lineTo(size.width, midY)
      ..lineTo(midX, size.height)
      ..lineTo(0, midY)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
