import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../game/models/game_models.dart';
import '../../game/models/game_state.dart';
import '../../game/widgets/game_board.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/tutorial_hand.dart';
import '../models/tutorial_steps.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late List<TutorialStep> _steps;
  late GameState _gameState;
  bool _showingHand = false;
  Position? _highlightPosition;

  late AnimationController _fadeController;
  late AnimationController _handController;

  @override
  void initState() {
    super.initState();
    _steps = TutorialSteps.allSteps;
    _gameState = GameState.initial(BoardLevel.traditional);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _handController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController.forward();
    _setupCurrentStep();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _handController.dispose();
    super.dispose();
  }

  void _setupCurrentStep() {
    final step = _steps[_currentStep];

    setState(() {
      if (step.setupState != null) {
        _gameState = step.setupState!;
      }
      _highlightPosition = step.highlightPosition;
      _showingHand = step.showHand;
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _setupCurrentStep();
        _fadeController.forward();
      });
    } else {
      // Tutorial complete
      _showCompletionDialog();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentStep--;
        });
        _setupCurrentStep();
        _fadeController.forward();
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text('Tutorial Complete!'),
          ],
        ),
        content: const Text(
          'You now know the basics of TigerHunt!\n\n'
          'Remember:\n'
          '• Tigers hunt by jumping over goats\n'
          '• Goats win by trapping all tigers\n'
          '• Strategy is key!',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Start Playing!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: AppTheme.parchment,
      appBar: AppBar(
        backgroundColor: AppTheme.parchment,
        elevation: 0,
        title: const Text(
          'Tutorial',
          style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),

              const SizedBox(height: 16),

              // Step title
              FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.terracotta,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Step description
              FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    step.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.charcoal.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Game board (interactive demo)
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Stack(
                      children: [
                        GameBoard(
                          level: BoardLevel.traditional,
                          gameState: _gameState,
                          selectedPosition: _highlightPosition,
                          validMoves: step.highlightMoves ?? [],
                          showHints: true,
                          onPositionTap: (_) {},
                        ),

                        // Animated hand pointer
                        if (_showingHand && step.handTarget != null)
                          TutorialHand(
                            animation: _handController,
                            targetPosition: step.handTarget!,
                            boardLevel: BoardLevel.traditional,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tip box
              if (step.tip != null)
                FadeTransition(
                  opacity: _fadeController,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.turmeric.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.turmeric.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.tip!,
                            style: const TextStyle(
                              color: AppTheme.henna,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Navigation buttons
              _buildNavigationButtons(),

              const SizedBox(height: 24),
            ],
          ),

          // Highlight overlay for specific areas
          if (step.overlayArea != null)
            TutorialOverlay(
              highlightArea: step.overlayArea!,
              animation: _fadeController,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: TextStyle(
                  color: AppTheme.charcoal.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                '${((_currentStep + 1) / _steps.length * 100).round()}%',
                style: TextStyle(
                  color: AppTheme.charcoal.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: AppTheme.sandalwood.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.terracotta),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _steps.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: OutlinedButton(
              onPressed: isFirstStep ? null : _previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.charcoal,
                side: BorderSide(
                  color: isFirstStep
                      ? AppTheme.sandalwood
                      : AppTheme.charcoal.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 8),
                  Text('Previous'),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Next button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastStep ? 'Finish' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isLastStep) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
