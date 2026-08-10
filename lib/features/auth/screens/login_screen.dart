import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/login_button.dart';
import '../widgets/decorative_border.dart';

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

  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String provider) async {
    setState(() => _isLoading = true);

    // Simulate login delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isLoading = false);
      // Navigate to home screen
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.cream,
              AppTheme.parchment,
              AppTheme.sandalwood,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.06),

                // Decorative top border
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const DecorativeBorder(),
                ),

                const SizedBox(height: 24),

                // Game logo/title
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Tiger & Goat icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAnimalIcon('🐯', AppTheme.tigerOrange),
                            const SizedBox(width: 20),
                            Text(
                              'VS',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.henna,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 20),
                            _buildAnimalIcon('🐐', AppTheme.forestGreen),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Game title
                        Text(
                          'TigerHunt',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: AppTheme.terracotta,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle - Bagh-Chal in English
                        Text(
                          'Bagh-Chal',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.henna,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Ancient Indian Strategy Game',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.inkBrown.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.06),

                // Login buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildLoginButtons(),
                  ),
                ),

                const SizedBox(height: 32),

                // Terms and privacy
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.inkBrown.withOpacity(0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Decorative bottom element
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const DecorativeBorder(isBottom: true),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalIcon(String emoji, Color bgColor) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: bgColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildComingSoonButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.6,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
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
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.turmeric,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Coming Soon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.henna.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.inkBrown.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Welcome, Player!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.charcoal,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to track your progress',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.inkBrown.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Google login - Coming Soon
          _buildComingSoonButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            iconColor: Colors.red,
            backgroundColor: Colors.white,
            textColor: AppTheme.charcoal,
            borderColor: Colors.grey.shade300,
          ),

          const SizedBox(height: 12),

          // Apple login - Coming Soon
          _buildComingSoonButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            iconColor: Colors.white,
            backgroundColor: AppTheme.charcoal,
            textColor: Colors.white,
          ),

          const SizedBox(height: 12),

          // Email login - Coming Soon
          _buildComingSoonButton(
            label: 'Continue with Email',
            icon: Icons.email_outlined,
            iconColor: AppTheme.peacockBlue,
            backgroundColor: AppTheme.peacockBlue.withOpacity(0.1),
            textColor: AppTheme.peacockBlue,
            borderColor: AppTheme.peacockBlue.withOpacity(0.3),
          ),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              Expanded(
                child: Divider(color: AppTheme.sandalwood.withOpacity(0.5)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: AppTheme.inkBrown.withOpacity(0.5),
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppTheme.sandalwood.withOpacity(0.5)),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Guest play
          LoginButton(
            label: 'Play as Guest',
            icon: Icons.person_outline,
            iconColor: AppTheme.forestGreen,
            backgroundColor: AppTheme.forestGreen.withOpacity(0.1),
            textColor: AppTheme.forestGreen,
            borderColor: AppTheme.forestGreen.withOpacity(0.3),
            onPressed: _isLoading ? null : () => _handleLogin('guest'),
          ),

          const SizedBox(height: 8),

          Text(
            'Guest progress won\'t be saved online',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.inkBrown.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
