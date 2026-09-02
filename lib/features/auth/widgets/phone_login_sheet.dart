import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class PhoneLoginSheet extends ConsumerStatefulWidget {
  const PhoneLoginSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PhoneLoginSheet(),
    );
  }

  @override
  ConsumerState<PhoneLoginSheet> createState() => _PhoneLoginSheetState();
}

class _CountryCode {
  final String name;
  final String code;
  final String flag;

  const _CountryCode(this.name, this.code, this.flag);
}

class _PhoneLoginSheetState extends ConsumerState<PhoneLoginSheet> {
  static const List<_CountryCode> _countries = [
    _CountryCode('India', '+91', '🇮🇳'),
    _CountryCode('Nepal', '+977', '🇳🇵'),
    _CountryCode('United States', '+1', '🇺🇸'),
    _CountryCode('United Kingdom', '+44', '🇬🇧'),
    _CountryCode('United Arab Emirates', '+971', '🇦🇪'),
    _CountryCode('Australia', '+61', '🇦🇺'),
    _CountryCode('Canada', '+1', '🇨🇦'),
    _CountryCode('Singapore', '+65', '🇸🇬'),
    _CountryCode('Bangladesh', '+880', '🇧🇩'),
  ];

  _CountryCode _selectedCountry = _countries[0];
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _isLogin = true; // True for Existing User, False for New User

  @override
  void dispose() {
    _phoneController.dispose();
    _passcodeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    String number = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (number.startsWith('+')) {
      return number;
    }
    if (number.startsWith('0')) {
      number = number.replaceFirst(RegExp(r'^0+'), '');
    }
    return '${_selectedCountry.code}$number';
  }

  Future<void> _handleDirectLogin() async {
    final rawNumber = _phoneController.text.trim().replaceAll(' ', '');
    if (rawNumber.length < 6) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }
    
    final passcode = _passcodeController.text.trim();
    if (passcode.length < 6) {
      setState(() => _errorMessage = 'Passcode must be at least 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = ref.read(authServiceProvider.notifier);
    final success = await auth.signInWithPhone(
      phoneNumber: _fullPhoneNumber,
      passcode: passcode,
      displayName: _displayNameController.text.trim(),
      isLogin: _isLogin,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      context.go('/play');
    } else {
      final err = ref.read(authServiceProvider).error;
      setState(() => _errorMessage = err ?? 'Login failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.tigerOrange.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.tigerOrange.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_android_rounded,
                          color: AppTheme.tigerOrange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Login with Mobile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _isLogin
                    ? 'Welcome back! Enter your mobile number and passcode to login.'
                    : 'Create a new account. Your mobile number is your unique player ID.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Tabs
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = true;
                          _errorMessage = null;
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isLogin ? AppTheme.tigerOrange : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Existing User',
                            style: TextStyle(
                              color: _isLogin ? Colors.white : Colors.white60,
                              fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isLogin = false;
                          _errorMessage = null;
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !_isLogin ? AppTheme.tigerOrange : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'New User',
                            style: TextStyle(
                              color: !_isLogin ? Colors.white : Colors.white60,
                              fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Phone Input with Country Selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    // Country Code Dropdown
                    DropdownButtonHideUnderline(
                      child: DropdownButton<_CountryCode>(
                        value: _selectedCountry,
                        dropdownColor: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: _countries.map((country) {
                          return DropdownMenuItem<_CountryCode>(
                            value: country,
                            child: Text(
                              '${country.flag} ${country.code}',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCountry = val);
                          }
                        },
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 12),
                    // Number field
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: InputDecoration(
                          hintText: '98765 43210',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onSubmitted: (_) => _handleDirectLogin(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Passcode field
              TextField(
                controller: _passcodeController,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: '6-Digit Passcode',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white54,
                    size: 20,
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
                onSubmitted: (_) => _handleDirectLogin(),
              ),
              const SizedBox(height: 16),

              // Player Name (optional) - Only for new users
              if (!_isLogin) ...[
                TextField(
                  controller: _displayNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Player Name (optional)',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      color: Colors.white54,
                      size: 20,
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
                  onSubmitted: (_) => _handleDirectLogin(),
                ),
                const SizedBox(height: 10),
              ],

              // Info hint
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Remember your passcode! You will need it to login again.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleDirectLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tigerOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isLogin ? Icons.login_rounded : Icons.person_add_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isLogin ? 'Login 🚀' : 'Create Account 🚀',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
