import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class GameRulesScreen extends StatefulWidget {
  const GameRulesScreen({super.key});

  @override
  State<GameRulesScreen> createState() => _GameRulesScreenState();
}

class _GameRulesScreenState extends State<GameRulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkerBg,
        elevation: 0,
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, color: AppTheme.tigerOrange, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Game Rules & Info',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.tigerOrange,
          indicatorWeight: 3,
          labelColor: AppTheme.tigerOrange,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabs: const [
            Tab(text: '📖 Basics & Objectives'),
            Tab(text: '🛡️ Anti-Repetition Rules'),
            Tab(text: '🎮 Power-Ups & Abilities'),
            Tab(text: '⚡ Timers & Sudden Death'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicsTab(),
          _buildAntiRepetitionTab(),
          _buildPowerUpsTab(),
          _buildTimersTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: Basics & Objectives
  // =========================================================================
  Widget _buildBasicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(
            title: 'Bagh-Chal (Tiger & Goats)',
            subtitle: 'Ancient Strategic Asymmetric Board Game',
            icon: '🐅 🆚 🐐',
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: '🎯 Objective & Win Conditions',
            accentColor: AppTheme.tigerOrange,
            children: [
              _buildRoleRow(
                emoji: '🐅',
                role: 'Tigers',
                goal: 'Hunt goats by jumping over them along connected board lines into empty spots behind them.',
                winCondition: 'Capture the target number of goats (e.g., 5 on Traditional board).',
              ),
              const Divider(color: Colors.white12, height: 24),
              _buildRoleRow(
                emoji: '🐐',
                role: 'Goats',
                goal: 'Coordinate and encircle the tigers until no tiger can make any legal moves or jumps.',
                winCondition: 'Trap and immobilize all tigers simultaneously.',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: '♟️ Two Game Phases',
            accentColor: AppTheme.greenAccent,
            children: [
              _buildBulletItem(
                title: 'Phase 1: Goat Placement',
                desc: 'Goats are placed on empty intersections one by one. During this phase, goats cannot move along lines, but tigers can move and capture.',
              ),
              const SizedBox(height: 12),
              _buildBulletItem(
                title: 'Phase 2: Movement Phase',
                desc: 'Once all goats are placed onto the board, goats can slide 1 step along connected lines to adjacent empty intersections.',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: '🗺️ Board Levels',
            accentColor: AppTheme.peacockBlue,
            children: [
              _buildLevelRow(
                icon: '🔺',
                level: 'Level 1: Pyramid',
                tigers: 3,
                goats: 12,
                capturesToWin: 3,
                description: 'Fast-paced triangular layout with corner anchors. Ideal for beginners.',
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildLevelRow(
                icon: '⬛',
                level: 'Level 2: Square',
                tigers: 4,
                goats: 16,
                capturesToWin: 4,
                description: 'Compact 5x5 grid without diagonals. Highly tactical maneuvering.',
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildLevelRow(
                icon: '✦',
                level: 'Level 3: Traditional',
                tigers: 5,
                goats: 20,
                capturesToWin: 5,
                description: 'Apex 5x5 board with 5 Tigers (4 Corners + 1 Center) and 20 Goats for maximum depth.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: Anti-Repetition & Move-Limit Rules
  // =========================================================================
  Widget _buildAntiRepetitionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(
            title: 'Fair Play & Anti-Stalemate Rules',
            subtitle: 'Eliminating Infinite Looping and Boring Stalemate Matches',
            icon: '🛡️ ⚖️ ⏱️',
          ),
          const SizedBox(height: 20),

          _buildRuleCard(
            title: '1. Threefold Repetition Rule',
            badge: 'Standard Tournament Rule',
            badgeColor: AppTheme.turmeric,
            icon: Icons.repeat,
            description:
                'If the exact identical board configuration (same piece positions, phase, and player turn) occurs 3 times during the match, the game automatically declares a Draw.',
            tip: 'Neither player can force an infinite cycle without consequence.',
          ),

          const SizedBox(height: 16),

          _buildRuleCard(
            title: '2. Anti-Oscillation (No 2-Spot Ping-Pong)',
            badge: 'Anti-Loop Filter',
            badgeColor: AppTheme.greenAccent,
            icon: Icons.sync_problem,
            description:
                'A Tiger or Goat is prevented from repeatedly bouncing back and forth between the exact same two positions (A ↔ B) more than twice consecutively if alternative legal moves exist on the board.',
            tip: 'Forces active gameplay progression instead of passive stalling.',
          ),

          const SizedBox(height: 16),

          _buildRuleCard(
            title: '3. 40-Move Stagnation Clock',
            badge: '50-Move Chess Equivalent',
            badgeColor: AppTheme.terracotta,
            icon: Icons.hourglass_bottom,
            description:
                'In the movement phase, if 40 consecutive moves are played without any goat being captured, the match concludes in a Draw.',
            tip:
                'A live alert banner appears at 20 moves to keep both players aware of the ticking clock.',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: Tactical Power-Ups & Abilities
  // =========================================================================
  Widget _buildPowerUpsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(
            title: 'Tactical Power-Ups',
            subtitle: 'Single-Use Strategic Abilities (1 per match per player)',
            icon: '⚡ 🛡️ 🪨 🐆',
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: '🐅 Tiger Abilities',
            accentColor: AppTheme.tigerOrange,
            children: [
              _buildAbilityRow(
                icon: '⚡',
                name: 'Tiger Roar',
                duration: '1 Turn',
                description:
                    'Unleashes a fierce roar that freezes an adjacent goat in place. The stunned goat is marked with a frost icon ❄️ and cannot move on the goat\'s next turn.',
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildAbilityRow(
                icon: '🐆',
                name: 'Super Pounce',
                duration: 'Instant',
                description:
                    'Allows a tiger to make a 2-step leap over an empty intersection along a line. Ideal for escaping tight encirclements or executing surprising flanking maneuvers.',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: '🐐 Goat Abilities',
            accentColor: AppTheme.greenAccent,
            children: [
              _buildAbilityRow(
                icon: '🛡️',
                name: 'Horn Shield',
                duration: '2 Turns',
                description:
                    'Enchants a chosen goat with golden protective invulnerability. Tigers cannot jump over or capture the shielded goat for 2 full turns.',
              ),
              const Divider(color: Colors.white12, height: 20),
              _buildAbilityRow(
                icon: '🪨',
                name: 'Boulder Obstacle',
                duration: '3 Turns',
                description:
                    'Places an impenetrable stone on an empty board intersection for 3 turns. Completely blocks tiger movement and jump trajectories.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 4: Timers & Sudden Death
  // =========================================================================
  Widget _buildTimersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(
            title: 'Speed, Timers & Sudden Death',
            subtitle: 'High-Stakes Clock Management & Dynamic Endgames',
            icon: '⏱️ ⚡ 🔥',
          ),
          const SizedBox(height: 20),

          _buildSectionCard(
            title: '⚡ Fischer Clock Increment',
            accentColor: AppTheme.turmeric,
            children: [
              _buildBulletItem(
                title: 'Bonus Time per Move (+2s / +3s / +5s)',
                desc:
                    'Whenever you complete a move, bonus seconds are instantly added to your clock. Fast play rewards players with time reserves, avoiding instant clock losses in complex endgames.',
              ),
              const SizedBox(height: 12),
              _buildBulletItem(
                title: 'Preset Formats',
                desc:
                    '• Bullet: 1 min (+2s)\n• Blitz: 3 min (+2s) or 5 min (+2s)\n• Rapid: 10 min (+3s) or 15 min (+5s)',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: '💓 Low-Time Heartbeat Alert',
            accentColor: Colors.redAccent,
            children: [
              _buildBulletItem(
                title: 'Under 10 Seconds Warning',
                desc:
                    'When either player’s clock drops below 10 seconds, the screen pulses with a dynamic red vignette and urgent heartbeat sound effects to intensify the rush.',
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: '🔥 Sudden Death: Shrinking Arena',
            accentColor: AppTheme.terracotta,
            children: [
              _buildBulletItem(
                title: 'Collapsing Outer Perimeter',
                desc:
                    'When Sudden Death is triggered, the outer board corners and edges progressively catch fire 🔥 every 20 seconds.',
              ),
              const SizedBox(height: 10),
              _buildBulletItem(
                title: 'Edge Elimination Penalty',
                desc:
                    '• Goats stranded on collapsing nodes are immediately eliminated/captured.\n• Tigers on collapsing nodes are pushed inwards toward the center.\n• Forces a thrilling, claustrophobic endgame showdown!',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Helper UI Widgets
  // =========================================================================

  Widget _buildHeroHeader({
    required String title,
    required String subtitle,
    required String icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardDark, AppTheme.darkerBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRoleRow({
    required String emoji,
    required String role,
    required String goal,
    required String winCondition,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                goal,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '🏆 Win: $winCondition',
                style: const TextStyle(
                  color: AppTheme.turmeric,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelRow({
    required String icon,
    required String level,
    required int tigers,
    required int goats,
    required int capturesToWin,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    level,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '🐅 $tigers | 🐐 $goats | 🎯 $capturesToWin Wins',
                    style: const TextStyle(
                      color: AppTheme.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required String description,
    required String tip,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: badgeColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: AppTheme.turmeric, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      color: AppTheme.turmeric,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityRow({
    required String icon,
    required String name,
    required String duration,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Duration: $duration',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem({required String title, required String desc}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
