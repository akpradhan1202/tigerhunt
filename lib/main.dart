import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/audio_service.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (skip in test environment)
  if (!const bool.fromEnvironment('flutter.test')) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // Attach the web audio unlock listeners before any user interaction so
  // the first tap makes sounds audible (browsers block autoplay).
  unawaited(AudioService.instance.init());

  // Set system UI style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF272522),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: TigerHuntApp()));
}

class TigerHuntApp extends ConsumerWidget {
  const TigerHuntApp({super.key});

  /// Whether the last orientation lock decision was portrait-only, so we
  /// only talk to [SystemChrome] when the device type actually changes.
  static bool? _lockPortrait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize AuthService with Firebase after Firebase is initialized
    ref.read(authServiceProvider.notifier).initializeFirebase();
    
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TigerHunt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        // Adapt orientation to the device: phones stay portrait, tablets and
        // desktops (and web) may freely rotate. Decided from the MediaQuery
        // inside the app so it reflects the real screen size.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final size = MediaQuery.sizeOf(context);
          final lockPortrait = size.shortestSide < 600;
          if (lockPortrait != _lockPortrait) {
            _lockPortrait = lockPortrait;
            SystemChrome.setPreferredOrientations(lockPortrait
                ? [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
                : DeviceOrientation.values);
          }
        });
        return child!;
      },
    );
  }
}
