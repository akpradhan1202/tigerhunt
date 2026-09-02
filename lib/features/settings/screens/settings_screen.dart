import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _soundFx = true;
  bool _vfxEnabled = true;
  bool _moveHints = true;
  double _volume = 0.8;

  @override
  void initState() {
    super.initState();
    _soundFx = AudioService.instance.soundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authServiceProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkerBg,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/play');
            }
          },
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Audio & Sounds Section
          _buildSectionHeader('AUDIO & SOUNDS', Icons.volume_up_outlined),
          const SizedBox(height: 10),
          _buildCard([
            SwitchListTile(
              title: const Text('Sound Effects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Tiger roars, goat blips, captures', style: TextStyle(color: Colors.white60, fontSize: 12)),
              value: _soundFx,
              activeTrackColor: AppTheme.tigerOrange,
              onChanged: (val) {
                setState(() => _soundFx = val);
                AudioService.instance.toggleSound();
                if (val) GameSound.buttonTap.play();
              },
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              title: const Text('Volume', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                activeColor: AppTheme.tigerOrange,
                inactiveColor: Colors.white24,
                onChanged: _soundFx
                    ? (val) {
                        setState(() => _volume = val);
                      }
                    : null,
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              title: const Text('Test Tiger Sound', style: TextStyle(color: Colors.white70, fontSize: 13)),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                label: const Text('Play 🐯', style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: _soundFx ? () => GameSound.tigerMove.play() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tigerOrange,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 28),

          // Gameplay & Visuals Section
          _buildSectionHeader('GAMEPLAY & VISUALS', Icons.sports_esports_outlined),
          const SizedBox(height: 10),
          _buildCard([
            SwitchListTile(
              title: const Text('Move Hints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Highlight valid destination circles on tap', style: TextStyle(color: Colors.white60, fontSize: 12)),
              value: _moveHints,
              activeTrackColor: AppTheme.greenAccent,
              onChanged: (val) => setState(() => _moveHints = val),
            ),
            const Divider(color: Colors.white12, height: 1),
            SwitchListTile(
              title: const Text('Visual Effects & Screen Shake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Juicy pounce effects and callout banners', style: TextStyle(color: Colors.white60, fontSize: 12)),
              value: _vfxEnabled,
              activeTrackColor: AppTheme.greenAccent,
              onChanged: (val) => setState(() => _vfxEnabled = val),
            ),
          ]),

          const SizedBox(height: 28),

          // Account & Profile Section
          _buildSectionHeader('ACCOUNT & PROFILE', Icons.person_outline),
          const SizedBox(height: 10),
          _buildCard([
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.tigerOrange,
                child: Text(
                  (user != null && user.displayName.isNotEmpty) ? user.displayName[0].toUpperCase() : '🐯',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              title: Text(
                user?.displayName ?? 'Player',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user?.isGuest == true ? 'Playing as Guest' : (user?.email ?? 'Logged In'),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out / Switch Player', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardDark,
                    title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
                    content: const Text('Do you want to sign out and return to the login screen?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authServiceProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
            ),
          ]),

          const SizedBox(height: 28),

          // Game Rules & About
          _buildSectionHeader('ABOUT', Icons.info_outline),
          const SizedBox(height: 10),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: AppTheme.tigerOrange),
              title: const Text('Bagh-Chal Rules & Tutorial', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () => context.go('/rules'),
            ),
            const Divider(color: Colors.white12, height: 1),
            const ListTile(
              leading: Icon(Icons.verified_outlined, color: Colors.white54),
              title: Text('TigerHunt Edition', style: TextStyle(color: Colors.white)),
              subtitle: Text('Version 1.0.0 (Web & Desktop)', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.tigerOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.tigerOrange,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }
}
