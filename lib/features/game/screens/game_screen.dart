import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/services/multiplayer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../models/game_models.dart';
import '../models/game_state.dart';
import '../models/game_engine.dart';
import '../models/ai_engine.dart';
import '../widgets/game_board.dart';
import '../../challenges/models/challenge_models.dart';
import '../../auth/providers/profile_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  final BoardLevel level;
  final GameMode mode;
  final GameTimer timer;
  final AIDifficulty? aiDifficulty;
  final PieceType? playerRole;

  /// Firestore match id when [mode] is [GameMode.online].
  final String? matchId;

  /// When set, the screen runs a tactical puzzle instead of a fresh game:
  /// the board starts at [Puzzle.position] and only the puzzle's solution
  /// moves are accepted.
  final Puzzle? puzzle;

  const GameScreen({
    super.key,
    required this.level,
    required this.mode,
    required this.timer,
    this.aiDifficulty,
    this.playerRole,
    this.matchId,
    this.puzzle,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late GameState _gameState;
  late GameEngine _engine;
  AIPlayer? _aiPlayer;
  bool _isAIThinking = false;

  Position? _selectedPosition;
  List<Move> _validMoves = [];
  Move? _lastMove;

  bool _showMoveHints = true;
  bool _soundEnabled = true;

  // Online mode
  StreamSubscription<OnlineMatch>? _onlineSub;
  int _appliedMoves = 0;
  bool _gameOverHandled = false;
  String? _myPlayerId;

  // Draw offer flow
  bool _drawDialogOpen = false;
  String? _lastDrawOffer;
  bool _drawResolved = false;

  // Tactical Power-Ups & Sudden Death
  PowerUpType? _selectedPowerUp;
  bool _suddenDeathTriggered = false;
  Timer? _suddenDeathIntervalTimer;
  int _collapseStep = 0;

  // Visual Effects & Callouts
  late AnimationController _shakeController;
  late AnimationController _calloutController;
  String? _calloutText;
  bool _vfxEnabled = true;

  // Timer & Inactivity
  Timer? _gameTimer;
  Timer? _inactivityTimer;
  int _idleSeconds = 0;
  Duration _tigerTime = Duration.zero;
  Duration _goatTime = Duration.zero;
  DateTime _turnStartTime = DateTime.now();

  // Puzzle mode
  int _puzzleMoveIndex = 0;
  bool _puzzleSolved = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _calloutController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _initGame();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _calloutController.dispose();
    _gameTimer?.cancel();
    _inactivityTimer?.cancel();
    _suddenDeathIntervalTimer?.cancel();
    _onlineSub?.cancel();

    // If exiting an in-progress online match without having resolved game over, notify opponent!
    if (_isOnline && widget.matchId != null && !_gameOverHandled && !_gameState.isGameOver) {
      final service = ref.read(multiplayerServiceProvider);
      final winner = widget.playerRole == PieceType.tiger
          ? GameWinner.goats
          : GameWinner.tigers;
      service
          .completeMatch(matchId: widget.matchId!, winner: winner)
          .catchError((Object _) {});
    }

    super.dispose();
  }

  void _initGame() {
    final puzzle = widget.puzzle;
    if (puzzle != null) {
      // Puzzle mode: start from the puzzle position with no opponent.
      _gameState = puzzle.position;
      _engine = GameEngine(puzzle.position.level);
      _selectedPosition = null;
      _validMoves = [];
      _lastMove = null;
      _isAIThinking = false;
      _gameOverHandled = false;
      _aiPlayer = null;
      _puzzleMoveIndex = 0;
      _puzzleSolved = false;
      _idleSeconds = 0;

      // Initialize audio and play start sound
      AudioService.instance.init();
      GameSound.gameStart.play();
      return;
    }

    _gameState = GameState.initial(widget.level, timer: widget.timer);
    _engine = GameEngine(widget.level);
    _selectedPosition = null;
    _validMoves = [];
    _lastMove = null;
    _isAIThinking = false;
    _gameOverHandled = false;
    _appliedMoves = 0;
    _myPlayerId = null;
    _drawDialogOpen = false;
    _lastDrawOffer = null;
    _drawResolved = false;
    _suddenDeathTriggered = false;
    _selectedPowerUp = null;
    _idleSeconds = 0;

    // Initialize audio and play start sound
    AudioService.instance.init();
    GameSound.gameStart.play();

    // Initialize timers
    _gameTimer?.cancel();
    _inactivityTimer?.cancel();
    _suddenDeathIntervalTimer?.cancel();

    if (widget.timer.hasLimit) {
      _tigerTime = widget.timer.duration;
      _goatTime = widget.timer.duration;
      _startTimer();
    }
    _startInactivityTimer();

    // Setup AI
    if (widget.aiDifficulty != null) {
      final aiPlaysAs = widget.playerRole == PieceType.goat
          ? PieceType.tiger
          : PieceType.goat;

      _aiPlayer = AIPlayer(
        gameEngine: _engine,
        difficulty: widget.aiDifficulty!,
        playingAs: aiPlaysAs,
      );

      if (aiPlaysAs == PieceType.goat) {
        Future.delayed(const Duration(milliseconds: 500), _makeAIMove);
      }
    }

    // Connect to the remote match for online play.
    if (widget.mode == GameMode.online) {
      _initOnline();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _idleSeconds = 0;
    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState.isGameOver || _gameState.isPaused) return;

      _idleSeconds++;

      // Inactivity warning at 45s (15s remaining)
      if (_idleSeconds == 45 && mounted) {
        if (_soundEnabled) GameSound.timerWarning.play();
        _triggerCallout('⚠️ Inactivity Warning: 15s to make a move!');
      }

      // Inactivity timeout at 60s
      if (_idleSeconds >= 60 && mounted) {
        timer.cancel();
        _handleInactivityTimeout();
        return;
      }

      // Refresh UI every second once idle for 30s so the countdown badge displays
      if (_idleSeconds >= 30 && mounted) {
        setState(() {});
      }
    });
  }

  void _handleInactivityTimeout() {
    if (_gameState.isGameOver || _gameOverHandled) return;
    _gameOverHandled = true;
    _inactivityTimer?.cancel();
    _gameTimer?.cancel();
    _suddenDeathIntervalTimer?.cancel();

    if (_gameState.moveHistory.isEmpty && _gameState.phase == GamePhase.placement) {
      // 0 moves played in the opening minute -> Abort game!
      setState(() {
        _gameState = _gameState.copyWith(
          phase: GamePhase.ended,
          winner: GameWinner.draw,
          drawReason: DrawReason.timeout,
        );
      });
      if (_isOnline && widget.matchId != null) {
        ref.read(multiplayerServiceProvider).cancelMatch(widget.matchId!).catchError((Object _) {});
      }
      _showGameAbortedDialog();
    } else {
      // Mid-game inactivity -> Current active turn player forfeits!
      final activeTurn = _gameState.currentTurn;
      final winner = activeTurn == PlayerTurn.tiger ? GameWinner.goats : GameWinner.tigers;
      setState(() {
        _gameState = _gameState.copyWith(
          winner: winner,
          phase: GamePhase.ended,
        );
      });
      if (_isOnline && widget.matchId != null) {
        ref.read(multiplayerServiceProvider).completeMatch(matchId: widget.matchId!, winner: winner).catchError((Object _) {});
      }
      _showGameOverDialog(inactivityForfeit: true);
    }
  }

  void _showGameAbortedDialog() {
    _gameOverHandled = true;
    _gameTimer?.cancel();
    _inactivityTimer?.cancel();
    _suddenDeathIntervalTimer?.cancel();
    if (_soundEnabled) GameSound.buttonTap.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Text('⏱️', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'Game Aborted',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'The game was aborted due to inactivity (1 minute idle without moves).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/play');
            },
            child: const Text('Exit to Home', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.mode == GameMode.online) {
                context.go('/online');
              } else {
                setState(() {
                  _gameOverHandled = false;
                  _initGame();
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
            child: const Text('Find New Match'),
          ),
        ],
      ),
    );
  }

  bool get _isOnline => widget.mode == GameMode.online;

  /// Board level used by the current board: the puzzle's level in puzzle mode.
  BoardLevel get _level => widget.puzzle?.position.level ?? widget.level;

  /// Whether it is the local player's turn in an online match.
  bool get _isMyTurn {
    final myRole = widget.playerRole;
    if (myRole == null) return true;
    return (myRole == PieceType.tiger &&
            _gameState.currentTurn == PlayerTurn.tiger) ||
        (myRole == PieceType.goat &&
            _gameState.currentTurn == PlayerTurn.goat);
  }

  void _initOnline() {
    final matchId = widget.matchId;
    if (matchId == null) return;

    final service = ref.read(multiplayerServiceProvider);
    _onlineSub?.cancel();
    _onlineSub = service.watchMatch(matchId).listen(
      _handleOnlineUpdate,
      onError: (Object _) {
        // Stream errors are rare; keep the local game usable.
      },
    );

    // Remember our player id so we can distinguish our own draw offers
    // from the opponent's.
    service.ensureReady().then((uid) {
      if (mounted) setState(() => _myPlayerId = uid);
    }).catchError((Object _) {});
  }

  void _handleOnlineUpdate(OnlineMatch match) {
    if (!mounted) return;

    // Handle draw offers from the opponent.
    final drawOffer = match.drawOffer;
    final myId = _myPlayerId;
    if (drawOffer != null &&
        myId != null &&
        drawOffer != myId &&
        !_gameOverHandled &&
        !_drawDialogOpen) {
      _drawDialogOpen = true;
      _showOnlineDrawDialog();
    } else if (drawOffer == null &&
        _lastDrawOffer == myId &&
        !_drawResolved &&
        match.status != MatchStatus.completed) {
      // Our offer was cleared without completing the match: declined.
      _showSnackBar('Your draw offer was declined.');
    }
    _lastDrawOffer = drawOffer;

    if (match.status == MatchStatus.completed) {
      if (!_gameOverHandled) {
        _gameOverHandled = true;
        _gameTimer?.cancel();
        _inactivityTimer?.cancel();
        _suddenDeathIntervalTimer?.cancel();

        if (match.winner == GameWinner.draw || match.moves.isEmpty) {
          _showGameAbortedDialog();
        } else {
          setState(() {
            _gameState = _gameState.copyWith(
              winner: match.winner,
              phase: GamePhase.ended,
            );
          });
          _showGameOverDialog();
        }
      }
      return;
    }

    if (match.status == MatchStatus.cancelled) {
      if (!_gameOverHandled) {
        _gameOverHandled = true;
        _gameTimer?.cancel();
        _inactivityTimer?.cancel();
        _suddenDeathIntervalTimer?.cancel();

        if (match.moves.isEmpty) {
          _showGameAbortedDialog();
        } else {
          _showOpponentLeftDialog();
        }
      }
      return;
    }

    // Apply any moves we have not seen yet (including moves made before we
    // joined the match).
    final moves = match.moves;
    if (moves.length > _appliedMoves) {
      setState(() {
        for (var i = _appliedMoves; i < moves.length; i++) {
          try {
            _gameState = _engine.executeMove(_gameState, moves[i]);
            _lastMove = moves[i];
            _idleSeconds = 0;
            _turnStartTime = DateTime.now();
            if (_soundEnabled) _soundForMove(moves[i]).play();
            if (moves[i].isCapture) {
              _triggerScreenShake();
              _triggerCallout('TIGER POUNCE! 🐯💥');
            }
          } catch (_) {
            // Ignore moves we cannot replay (should not happen).
          }
        }
        _appliedMoves = moves.length;
        _selectedPosition = null;
        _validMoves = [];
      });

      if (_gameState.isGameOver) {
        _showGameOverDialog();
      }
    }

    // Apply any Sudden Death board collapses triggered by the opponent
    if (match.collapsedPositions.length > _gameState.collapsedPositions.length) {
      final newCollapsing = match.collapsedPositions
          .toSet()
          .difference(_gameState.collapsedPositions);
      if (newCollapsing.isNotEmpty) {
        setState(() {
          _gameState = _engine.triggerArenaCollapse(_gameState, newCollapsing);
          _suddenDeathTriggered = true;
        });
        _triggerScreenShake();
        _triggerCallout('🔥 SUDDEN DEATH: ARENA COLLAPSE! 🔥');
        if (_soundEnabled) GameSound.tigerCapture.play();
        _showSnackBar('🔥 Sudden Death: Outer tiles engulfed in flames! Pieces pushed inward.');
        if (_gameState.isGameOver) {
          _showGameOverDialog();
        }
      }
    }
  }

  void _showOpponentLeftDialog() {
    _gameTimer?.cancel();
    _inactivityTimer?.cancel();
    _suddenDeathIntervalTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Opponent Left',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Your opponent disconnected or resigned.\nYou win! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/play');
            },
            child: const Text('Back to Home', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/online');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
            child: const Text('Find New Match'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState.isGameOver || _gameState.isPaused) return;

      setState(() {
        if (_gameState.currentTurn == PlayerTurn.tiger) {
          _tigerTime -= const Duration(seconds: 1);
          // Timer warning sound at 10 seconds
          if (_tigerTime.inSeconds == 10 && _soundEnabled) {
            GameSound.timerWarning.play();
          }
          if (_tigerTime.inSeconds <= 0) {
            _tigerTime = Duration.zero;
            _handleTimeOut(PlayerTurn.tiger);
          }
        } else {
          _goatTime -= const Duration(seconds: 1);
          // Timer warning sound at 10 seconds
          if (_goatTime.inSeconds == 10 && _soundEnabled) {
            GameSound.timerWarning.play();
          }
          if (_goatTime.inSeconds <= 0) {
            _goatTime = Duration.zero;
            _handleTimeOut(PlayerTurn.goat);
          }
        }
      });
    });
  }

  void _handleTimeOut(PlayerTurn player) {
    _gameTimer?.cancel();
    final winner = player == PlayerTurn.tiger ? GameWinner.goats : GameWinner.tigers;
    setState(() {
      _gameState = _gameState.copyWith(
        winner: winner,
        phase: GamePhase.ended,
      );
    });
    if (_isOnline && widget.matchId != null) {
      ref
          .read(multiplayerServiceProvider)
          .completeMatch(matchId: widget.matchId!, winner: winner)
          .catchError((Object _) {});
    }
    _showGameOverDialog(timeOut: true);
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _makeAIMove() async {
    if (_aiPlayer == null || _gameState.isGameOver || _isAIThinking) return;

    final isAITurn = (_aiPlayer!.playingAs == PieceType.tiger &&
            _gameState.currentTurn == PlayerTurn.tiger) ||
        (_aiPlayer!.playingAs == PieceType.goat &&
            _gameState.currentTurn == PlayerTurn.goat);

    if (!isAITurn) return;

    setState(() => _isAIThinking = true);

    await Future.delayed(const Duration(milliseconds: 300));

    final move = await _aiPlayer!.getMove(_gameState);

    if (move != null && mounted) {
      // Play sound for AI move
      if (_soundEnabled) _soundForMove(move).play();

      setState(() {
        _gameState = _engine.executeMove(_gameState, move);
        _lastMove = move;
        _selectedPosition = null;
        _validMoves = [];
        _isAIThinking = false;
        _idleSeconds = 0;
      });

      if (_gameState.isGameOver) {
        _showGameOverDialog();
      }
    } else if (mounted) {
      setState(() => _isAIThinking = false);
    }
  }

  void _onPositionTap(Position pos) {
    if (_gameState.isGameOver) return;
    if (_isAIThinking) return;
    if (_isOnline && !_isMyTurn) return;

    if (_aiPlayer != null) {
      final isAITurn = (_aiPlayer!.playingAs == PieceType.tiger &&
              _gameState.currentTurn == PlayerTurn.tiger) ||
          (_aiPlayer!.playingAs == PieceType.goat &&
              _gameState.currentTurn == PlayerTurn.goat);
      if (isAITurn) return;
    }

    // Check for power-up targeting
    if (_selectedPowerUp != null) {
      final powerUp = _selectedPowerUp!;
      final piece = _gameState.getPieceAt(pos);

      if (powerUp == PowerUpType.tigerRoar) {
        if (piece != null && piece.type == PieceType.goat) {
          final isNearTiger = _gameState.tigers.any((t) => t.position.isAdjacentTo(pos));
          if (isNearTiger) {
            setState(() {
              _gameState = _engine.applyPowerUp(
                _gameState,
                powerUp: PowerUpType.tigerRoar,
                target: pos,
              );
              _selectedPowerUp = null;
            });
            if (_soundEnabled) GameSound.tigerCapture.play();
            _showSnackBar('⚡ Tiger Roar! Goat frozen for 1 turn.');
            return;
          } else {
            _showSnackBar('Roar only affects goats next to a tiger!');
            return;
          }
        }
      } else if (powerUp == PowerUpType.hornShield) {
        if (piece != null && piece.type == PieceType.goat) {
          setState(() {
            _gameState = _engine.applyPowerUp(
              _gameState,
              powerUp: PowerUpType.hornShield,
              target: pos,
            );
            _selectedPowerUp = null;
          });
          if (_soundEnabled) GameSound.gameStart.play();
          _showSnackBar('🛡️ Horn Shield activated for 2 turns!');
          return;
        }
      } else if (powerUp == PowerUpType.boulder) {
        if (_gameState.isPositionEmpty(pos)) {
          setState(() {
            _gameState = _engine.applyPowerUp(
              _gameState,
              powerUp: PowerUpType.boulder,
              target: pos,
            );
            _selectedPowerUp = null;
          });
          if (_soundEnabled) GameSound.buttonTap.play();
          _triggerCallout('BOULDER PLACED! 🪨');
          _showSnackBar('🪨 Boulder placed on intersection for 3 turns!');
          return;
        }
      } else if (powerUp == PowerUpType.superPounce) {
        if (piece != null && piece.type == PieceType.tiger) {
          final pounceMoves = <Move>[];
          for (final neighbor in _engine.connections.getNeighbors(pos)) {
            if (_gameState.isPositionEmpty(neighbor)) {
              final leapDest = _engine.connections.getJumpDestination(pos, neighbor);
              if (leapDest != null && _gameState.isPositionEmpty(leapDest)) {
                pounceMoves.add(Move(
                  from: pos,
                  to: leapDest,
                  pieceType: PieceType.tiger,
                ));
              }
            }
          }
          if (pounceMoves.isNotEmpty) {
            setState(() {
              _selectedPosition = pos;
              _validMoves = pounceMoves;
            });
            _showSnackBar('Select highlighted landing square for Super Pounce!');
            return;
          } else {
            _showSnackBar('No 2-step leaps available for this tiger.');
            return;
          }
        }
      }
    }

    final piece = _gameState.getPieceAt(pos);

    if (_selectedPosition == null) {
      if (_gameState.phase == GamePhase.placement &&
          _gameState.currentTurn == PlayerTurn.goat) {
        if (_gameState.isPositionEmpty(pos)) {
          _placeGoat(pos);
        }
        return;
      }

      if (piece != null) {
        final isTigerTurn = _gameState.currentTurn == PlayerTurn.tiger;
        final isGoatTurn = _gameState.currentTurn == PlayerTurn.goat;

        if ((isTigerTurn && piece.type == PieceType.tiger) ||
            (isGoatTurn && piece.type == PieceType.goat)) {
          if (_soundEnabled) GameSound.select.play();
          setState(() {
            _selectedPosition = pos;
            _validMoves = _engine
                .getValidMoves(_gameState)
                .where((m) => m.from == pos)
                .toList();
          });
        }
      }
    } else {
      final move = _validMoves.firstWhere(
        (m) => m.to == pos,
        orElse: () => const Move(
          from: Position(-1, -1),
          to: Position(-1, -1),
          pieceType: PieceType.goat,
        ),
      );

      if (move.from != const Position(-1, -1)) {
        _executeMove(move);
      } else if (piece != null && piece.position != _selectedPosition) {
        final isTigerTurn = _gameState.currentTurn == PlayerTurn.tiger;
        if ((isTigerTurn && piece.type == PieceType.tiger) ||
            (!isTigerTurn && piece.type == PieceType.goat)) {
          setState(() {
            _selectedPosition = pos;
            _validMoves = _engine
                .getValidMoves(_gameState)
                .where((m) => m.from == pos)
                .toList();
          });
        }
      } else {
        setState(() {
          _selectedPosition = null;
          _validMoves = [];
        });
      }
    }
  }

  void _placeGoat(Position pos) {
    final move = Move(
      from: const Position(-1, -1),
      to: pos,
      pieceType: PieceType.goat,
    );

    if (_engine.isValidMove(_gameState, move)) {
      _executeMove(move);
    }
  }

  /// Pick the sound for a move
  GameSound _soundForMove(Move move) {
    if (move.isCapture) return GameSound.tigerCapture;
    if (move.pieceType == PieceType.tiger) return GameSound.tigerMove;
    return GameSound.goatMove;
  }

  void _triggerScreenShake() {
    _shakeController.forward(from: 0.0);
  }

  void _triggerCallout(String text) {
    setState(() => _calloutText = text);
    _calloutController.forward(from: 0.0);
  }

  void _executeMove(Move move) {
    if (_isAIThinking) return;
    final matchId = widget.matchId;

    // Consume super pounce if active
    if (_selectedPowerUp == PowerUpType.superPounce) {
      final used = Map<PlayerTurn, Set<PowerUpType>>.from(_gameState.usedPowerUps);
      final currentUsed = Set<PowerUpType>.from(used[_gameState.currentTurn] ?? {});
      currentUsed.add(PowerUpType.superPounce);
      used[_gameState.currentTurn] = currentUsed;
      _gameState = _gameState.copyWith(usedPowerUps: used);
      _selectedPowerUp = null;
      _triggerCallout('SUPER POUNCE! 🐆⚡');
    }

    final moveDuration = DateTime.now().difference(_turnStartTime);
    _turnStartTime = DateTime.now();

    // Fast move speed bounce bonus: if move was made within 3 seconds, award +2s!
    if (moveDuration.inSeconds <= 3 && widget.timer != GameTimer.unlimited) {
      if (move.pieceType == PieceType.tiger) {
        _tigerTime += const Duration(seconds: 2);
      } else {
        _goatTime += const Duration(seconds: 2);
      }
      _triggerCallout('⚡ FAST MOVE: +2s BONUS! ⚡');
    } else if (widget.timer.incrementSeconds > 0) {
      // Apply standard Fischer increment if configured
      if (move.pieceType == PieceType.tiger) {
        _tigerTime += widget.timer.increment;
      } else {
        _goatTime += widget.timer.increment;
      }
      _triggerCallout('+${widget.timer.incrementSeconds}s SPEED BONUS ⚡');
    }

    // Trigger juicy effects on capture
    if (move.isCapture) {
      _triggerScreenShake();
      _triggerCallout('TIGER POUNCE! 🐯💥');
    }

    // Puzzle mode: only the solution move is accepted.
    final puzzle = widget.puzzle;
    if (puzzle != null && !_puzzleSolved) {
      final expected = puzzle.solution[_puzzleMoveIndex];
      final isSolutionMove = move.from == expected.from &&
          move.to == expected.to &&
          move.capturedAt == expected.capturedAt;
      if (!isSolutionMove) {
        if (_soundEnabled) GameSound.buttonTap.play();
        _showSnackBar("That's not the solution move — try again!");
        return;
      }

      setState(() {
        _gameState = _engine.executeMove(_gameState, move);
        _lastMove = move;
        _selectedPosition = null;
        _validMoves = [];
        _puzzleMoveIndex++;
      });

      if (_puzzleMoveIndex >= puzzle.solution.length) {
        _puzzleSolved = true;
        _showPuzzleSolvedDialog(puzzle);
      } else {
        setState(() {
          _gameState = _gameState.copyWith(
            currentTurn: puzzle.playerRole == PieceType.tiger
                ? PlayerTurn.tiger
                : PlayerTurn.goat,
          );
        });
        _showSnackBar('Correct! Find the next move.');
      }
      return;
    }

    // Play appropriate sound
    if (_soundEnabled) _soundForMove(move).play();

    // Check if move is custom super pounce jump
    GameState nextState;
    if (move.pieceType == PieceType.tiger &&
        !move.isCapture &&
        !move.isPlacement &&
        !_engine.connections.getNeighbors(move.from).contains(move.to)) {
      // Super pounce displacement
      final updatedPieces = _gameState.pieces.map((p) {
        if (p.position == move.from && p.type == PieceType.tiger && !p.isCaptured) {
          return p.copyWith(position: move.to);
        }
        return p;
      }).toList();
      nextState = _gameState.copyWith(
        pieces: updatedPieces,
        currentTurn: PlayerTurn.goat,
        moveHistory: [..._gameState.moveHistory, move],
      );
    } else {
      nextState = _engine.executeMove(_gameState, move);
    }

    if (_engine.areTigersTrapped(nextState)) {
      _triggerCallout('TIGERS TRAPPED! 🐐🔒');
    }

    setState(() {
      _gameState = nextState;
      _lastMove = move;
      _selectedPosition = null;
      _validMoves = [];
      _idleSeconds = 0;
    });

    if (_gameState.isGameOver) {
      _showGameOverDialog();
    } else if (_aiPlayer != null) {
      Future.delayed(const Duration(milliseconds: 200), _makeAIMove);
    }

    // In online mode, push the move to Firestore
    if (_isOnline && matchId != null) {
      _appliedMoves++;
      final service = ref.read(multiplayerServiceProvider);
      service
          .sendMove(matchId: matchId, move: move)
          .catchError((Object _) {});
      if (_gameState.isGameOver) {
        service
            .completeMatch(
              matchId: matchId,
              winner: _gameState.winner,
            )
            .catchError((Object _) {});
      }
    }
  }

  void _showGameOverDialog({bool timeOut = false, bool inactivityForfeit = false}) {
    if (_gameOverHandled) return;
    _gameOverHandled = true;

    _gameTimer?.cancel();
    _inactivityTimer?.cancel();
    _suddenDeathIntervalTimer?.cancel();

    final winner = _gameState.winner;
    String title;
    String message;
    String emoji;

    bool playerWon = false;
    if (widget.playerRole == PieceType.tiger && winner == GameWinner.tigers) {
      playerWon = true;
    } else if (widget.playerRole == PieceType.goat && winner == GameWinner.goats) {
      playerWon = true;
    } else if (winner == GameWinner.draw) {
      playerWon = false;
    }

    if (_soundEnabled) {
      if (playerWon) {
        GameSound.gameWin.play();
      } else {
        GameSound.gameLose.play();
      }
    }

    switch (winner) {
      case GameWinner.tigers:
        title = 'Tigers Win!';
        message = inactivityForfeit
            ? 'Goats forfeited due to 1 minute inactivity.'
            : (timeOut
                ? 'Goats ran out of time!'
                : 'The tigers captured ${_gameState.goatsCaptured} goats.');
        emoji = '🐯';
        break;
      case GameWinner.goats:
        title = 'Goats Win!';
        message = inactivityForfeit
            ? 'Tigers forfeited due to 1 minute inactivity.'
            : (timeOut
                ? 'Tigers ran out of time!'
                : 'The goats trapped all tigers!');
        emoji = '🐐';
        break;
      case GameWinner.draw:
        title = 'Draw!';
        if (_gameState.drawReason == DrawReason.threefoldRepetition) {
          message = 'Threefold Repetition! 🤝 The exact same board position occurred 3 times.';
        } else if (_gameState.drawReason == DrawReason.stagnation) {
          message = '40-Move Rule! 🤝 40 moves occurred without a goat capture.';
        } else {
          message = 'The game ended in a draw.';
        }
        emoji = '🤝';
        break;
      default:
        return;
    }

    ref.read(profileProvider.notifier).recordGameResult(
          winner: winner,
          playerRole: widget.playerRole ?? PieceType.goat,
          mode: widget.mode,
          aiDifficulty: widget.aiDifficulty,
        );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/play');
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.mode == GameMode.online) {
                context.go('/online');
              } else {
                setState(() {
                  _gameOverHandled = false;
                  _initGame();
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showPuzzleSolvedDialog(Puzzle puzzle) {
    _gameTimer?.cancel();
    if (_soundEnabled) GameSound.gameWin.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Text('🧩', style: TextStyle(fontSize: 48)),
            SizedBox(height: 8),
            Text(
              'Puzzle Solved!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              puzzle.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (puzzle.explanation != null)
              Text(
                puzzle.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _initGame());
            },
            child: const Text('Replay', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/puzzles');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
            child: const Text('Back to Puzzles'),
          ),
        ],
      ),
    );
  }

  void _showPuzzleHint(Puzzle puzzle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Puzzle Hint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          puzzle.explanation ??
              '${puzzle.description}\nPlay as ${puzzle.playerRole.name}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.peacockBlue),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _onResign() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resign?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to resign?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.pop(context);
              if (_isOnline && widget.matchId != null) {
                _gameOverHandled = true;
                _gameTimer?.cancel();
                _inactivityTimer?.cancel();
                _suddenDeathIntervalTimer?.cancel();
                final winner = widget.playerRole == PieceType.tiger
                    ? GameWinner.goats
                    : GameWinner.tigers;
                try {
                  await ref
                      .read(multiplayerServiceProvider)
                      .completeMatch(matchId: widget.matchId!, winner: winner);
                } catch (e) {
                  debugPrint('Error completing match on resign: $e');
                }
              }
              if (mounted) {
                router.go('/play');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  /// Roll the board back to before the last human move (and, in AI games,
  /// the AI's reply too). Online matches cannot be rolled back because the
  /// history is shared with the opponent.
  void _onUndo() {
    if (_gameState.moveHistory.isEmpty || _gameState.isGameOver) return;
    if (_isAIThinking) return;
    if (_isOnline) return;

    final history = _gameState.moveHistory;
    int movesToUndo;
    if (_aiPlayer != null) {
      // It is the human's turn after the AI replied, so take back both the
      // human's last move and the AI's response.
      final isHumanTurn =
          (widget.playerRole == PieceType.tiger &&
              _gameState.currentTurn == PlayerTurn.tiger) ||
          (widget.playerRole == PieceType.goat &&
              _gameState.currentTurn == PlayerTurn.goat);
      movesToUndo = isHumanTurn ? (history.length >= 2 ? 2 : 1) : 1;
    } else {
      // Pass & play: take back a single move.
      movesToUndo = 1;
    }

    final keep = history.length - movesToUndo;
    final rebuilt = _engine.replayMoves(_gameState, keep, timer: widget.timer);
    if (_soundEnabled) GameSound.buttonTap.play();
    setState(() {
      _gameState = rebuilt;
      _lastMove = rebuilt.moveHistory.isEmpty
          ? null
          : rebuilt.moveHistory.last;
      _selectedPosition = null;
      _validMoves = [];
    });
  }

  /// Start the draw flow: a confirm dialog offline, or a Firestore offer
  /// online.
  void _onDraw() {
    if (_gameState.isGameOver) return;
    if (_soundEnabled) GameSound.buttonTap.play();
    if (_isOnline) {
      _offerOnlineDraw();
      return;
    }
    _offerOfflineDraw();
  }

  void _offerOfflineDraw() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Offer a draw?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'The game will end with both players sharing the point.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
            child: const Text('Offer Draw'),
          ),
        ],
      ),
    ).then((offered) {
      if (offered != true || !mounted) return;
      if (_aiPlayer != null) {
        // The AI graciously accepts.
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _finishDraw();
        });
      } else {
        // Pass & play: hand the device to the other player to decide.
        _confirmPassAndPlayDraw();
      }
    });
  }

  void _confirmPassAndPlayDraw() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Other player: accept the draw?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Pass the device. Accepting ends the game in a draw.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Decline', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
            child: const Text('Accept'),
          ),
        ],
      ),
    ).then((accepted) {
      if (accepted == true && mounted) _finishDraw();
    });
  }

  void _finishDraw() {
    setState(() {
      _gameState = _gameState.copyWith(
        winner: GameWinner.draw,
        phase: GamePhase.ended,
      );
    });
    _showGameOverDialog();
  }

  void _offerOnlineDraw() {
    final matchId = widget.matchId;
    final myId = _myPlayerId;
    if (matchId == null || myId == null) {
      _showSnackBar('Draw unavailable yet — try again in a moment.');
      return;
    }
    ref
        .read(multiplayerServiceProvider)
        .offerDraw(matchId: matchId, playerId: myId)
        .catchError((Object _) {
      if (mounted) _showSnackBar('Could not send the draw offer.');
    });
    _showSnackBar('Draw offer sent.');
  }

  void _showOnlineDrawDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Draw Offer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Your opponent offers a draw. Accept?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              _respondToOnlineDraw(accept: false);
            },
            child: const Text('Decline', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              _respondToOnlineDraw(accept: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenAccent),
            child: const Text('Accept'),
          ),
        ],
      ),
    ).whenComplete(() => _drawDialogOpen = false);
  }

  Future<void> _respondToOnlineDraw({required bool accept}) async {
    _drawResolved = true;
    final matchId = widget.matchId;
    if (matchId == null) return;
    await ref
        .read(multiplayerServiceProvider)
        .respondToDraw(matchId: matchId, accept: accept)
        .catchError((Object _) {});
    if (accept && mounted) {
      _showSnackBar('Draw accepted.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.cardDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTigerTurn = _gameState.currentTurn == PlayerTurn.tiger;
    final isPlayerTiger = widget.playerRole == PieceType.tiger;

    return PopScope(
      canPop: widget.puzzle != null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onResign();
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700 &&
                      constraints.maxWidth > constraints.maxHeight * 0.85;

                  if (isWide) {
                    return Column(
                      children: [
                        // Top bar
                        _buildTopBar(),

                        // Stagnation / 40-move banner
                        _buildStagnationBanner(),

                        // Side-by-side gameplay area
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left / Center: Large Game board occupying maximum available space
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: _wrapWithScreenShake(
                                        child: GameBoard(
                                          level: _level,
                                          gameState: _gameState,
                                          selectedPosition: _selectedPosition,
                                          validMoves: _validMoves,
                                          lastMove: _lastMove,
                                          showHints: _showMoveHints,
                                          onPositionTap: _onPositionTap,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Right: Sidebar with players, status, powerups, and controls
                                SizedBox(
                                  width: 320,
                                  child: Center(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildPlayerBar(
                                            name: _aiPlayer != null
                                                ? 'AI ${widget.aiDifficulty?.name ?? ''}'
                                                : _isOnline
                                                    ? 'Online Player'
                                                    : (isPlayerTiger ? 'Goats' : 'Tigers'),
                                            emoji: isPlayerTiger ? '🐐' : '🐯',
                                            isCurrentTurn: isPlayerTiger ? !isTigerTurn : isTigerTurn,
                                            time: isPlayerTiger ? _goatTime : _tigerTime,
                                            isTop: true,
                                            capturedCount: isPlayerTiger ? 0 : _gameState.goatsCaptured,
                                          ),
                                          const SizedBox(height: 8),
                                          if (_gameState.phase == GamePhase.placement)
                                            Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 16),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: AppTheme.cardDark,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Text('🐐', style: TextStyle(fontSize: 18)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${_gameState.goatsToPlace} goats to place',
                                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          _buildActiveAbilityBanner(),
                                          const SizedBox(height: 8),
                                          _buildPlayerBar(
                                            name: 'You',
                                            emoji: isPlayerTiger ? '🐯' : '🐐',
                                            isCurrentTurn: isPlayerTiger ? isTigerTurn : !isTigerTurn,
                                            time: isPlayerTiger ? _tigerTime : _goatTime,
                                            isTop: false,
                                            capturedCount: isPlayerTiger ? _gameState.goatsCaptured : 0,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildBottomControls(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Mobile / Portrait layout
                  return Column(
                    children: [
                      // Top bar with back button and game info
                      _buildTopBar(),

                      // Stagnation warning banner
                      _buildStagnationBanner(),

                      // Opponent (top) info bar
                      _buildPlayerBar(
                        name: _aiPlayer != null
                            ? 'AI ${widget.aiDifficulty?.name ?? ''}'
                            : _isOnline
                                ? 'Online Player'
                                : (isPlayerTiger ? 'Goats' : 'Tigers'),
                        emoji: isPlayerTiger ? '🐐' : '🐯',
                        isCurrentTurn: isPlayerTiger ? !isTigerTurn : isTigerTurn,
                        time: isPlayerTiger ? _goatTime : _tigerTime,
                        isTop: true,
                        capturedCount: isPlayerTiger ? 0 : _gameState.goatsCaptured,
                        showGoatsToPlace: isPlayerTiger && _gameState.phase == GamePhase.placement,
                      ),

                      // Game board (takes maximum available screen space!)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: _wrapWithScreenShake(
                              child: GameBoard(
                                level: _level,
                                gameState: _gameState,
                                selectedPosition: _selectedPosition,
                                validMoves: _validMoves,
                                lastMove: _lastMove,
                                showHints: _showMoveHints,
                                onPositionTap: _onPositionTap,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Active ability banner (only visible when an ability is activated)
                      _buildActiveAbilityBanner(),

                      // Player (bottom) info bar
                      _buildPlayerBar(
                        name: 'You',
                        emoji: isPlayerTiger ? '🐯' : '🐐',
                        isCurrentTurn: isPlayerTiger ? isTigerTurn : !isTigerTurn,
                        time: isPlayerTiger ? _tigerTime : _goatTime,
                        isTop: false,
                        capturedCount: isPlayerTiger ? _gameState.goatsCaptured : 0,
                        showGoatsToPlace: !isPlayerTiger && _gameState.phase == GamePhase.placement,
                      ),

                      // Bottom icon controls
                      _buildBottomControls(),
                    ],
                  );
                },
              ),
              _buildLowTimeVignette(),
              _buildFloatingCallout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: AppTheme.darkerBg,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            visualDensity: VisualDensity.compact,
            onPressed: widget.puzzle != null
                ? () => Navigator.of(context).pop()
                : _onResign,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.puzzle?.title ?? _level.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.timer.hasLimit) ...[
                    const SizedBox(width: 4),
                    Container(width: 1, height: 12, color: Colors.white24),
                    const SizedBox(width: 4),
                    const Icon(Icons.timer, color: Colors.white70, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      widget.timer.label,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isAIThinking) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.greenAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.greenAccent),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Thinking...',
                    style: TextStyle(color: AppTheme.greenAccent, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
          if (_idleSeconds >= 30 && !_gameState.isGameOver) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: (_idleSeconds >= 45 ? AppTheme.terracotta : Colors.amber).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _idleSeconds >= 45 ? AppTheme.terracotta : Colors.amber,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    color: _idleSeconds >= 45 ? AppTheme.terracotta : Colors.amber,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${60 - _idleSeconds}s',
                    style: TextStyle(
                      color: _idleSeconds >= 45 ? AppTheme.terracotta : Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              _showMoveHints ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showMoveHints ? AppTheme.turmeric : Colors.white54,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              if (_soundEnabled) GameSound.buttonTap.play();
              setState(() => _showMoveHints = !_showMoveHints);
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: AppTheme.tigerOrange, size: 18),
            tooltip: 'Game Rules & Info',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            visualDensity: VisualDensity.compact,
            onPressed: () => context.push('/rules'),
          ),
          IconButton(
            icon: Icon(
              _soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: _soundEnabled ? AppTheme.greenAccent : Colors.white54,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
                if (_soundEnabled) {
                  AudioService.instance.enableSound();
                  GameSound.buttonTap.play();
                } else {
                  AudioService.instance.disableSound();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar({
    required String name,
    required String emoji,
    required bool isCurrentTurn,
    required Duration time,
    required bool isTop,
    int capturedCount = 0,
    bool showGoatsToPlace = false,
  }) {
    final hasTimer = widget.timer.hasLimit;
    final isLowTime = time.inSeconds <= 30 && hasTimer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentTurn ? AppTheme.cardDark : AppTheme.darkerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentTurn ? AppTheme.greenAccent : Colors.white10,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCurrentTurn
                  ? AppTheme.greenAccent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),

          // Name, placement status & captured count
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showGoatsToPlace) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_gameState.goatsToPlace} to place',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (capturedCount > 0) ...[
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      capturedCount.clamp(0, 5),
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(
                          emoji == '🐯' ? '🐐' : '🐯',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Timer
          if (hasTimer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isLowTime
                    ? AppTheme.terracotta.withValues(alpha: 0.3)
                    : (isCurrentTurn ? AppTheme.greenAccent.withValues(alpha: 0.2) : Colors.white12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isLowTime ? AppTheme.terracotta : Colors.transparent,
                ),
              ),
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  color: isLowTime
                      ? AppTheme.terracotta
                      : (isCurrentTurn ? AppTheme.greenAccent : Colors.white70),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    if (widget.puzzle != null) return _buildPuzzleFooter();

    final canUndo = !_isOnline &&
        !_isAIThinking &&
        !_gameState.isGameOver &&
        _gameState.moveHistory.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: AppTheme.darkerBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconAction(
            icon: Icons.more_horiz,
            label: 'Options',
            color: Colors.white70,
            onTap: _showOptionsSheet,
          ),
          if (!_suddenDeathTriggered &&
              !_gameState.isGameOver &&
              _gameState.phase == GamePhase.movement)
            _buildIconAction(
              icon: Icons.local_fire_department,
              label: 'Collapse 🔥',
              color: AppTheme.tigerOrange,
              onTap: _triggerSuddenDeath,
            )
          else if (_suddenDeathTriggered && !_gameState.isGameOver)
            _buildIconAction(
              icon: Icons.local_fire_department,
              label: 'Stage $_collapseStep 🔥',
              color: Colors.deepOrangeAccent,
              onTap: () {
                _showSnackBar('🔥 Sudden Death Active! Outer board tiles collapse every 20s.');
              },
            ),
          _buildIconAction(
            icon: Icons.bolt,
            label: 'Abilities',
            color: _selectedPowerUp != null ? AppTheme.turmeric : Colors.white70,
            onTap: _showAbilitiesSheet,
          ),
          _buildIconAction(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            color: Colors.white70,
            onTap: _showChatModal,
          ),
          _buildIconAction(
            icon: Icons.undo,
            label: 'Undo',
            color: canUndo ? AppTheme.greenAccent : Colors.white24,
            onTap: canUndo ? _onUndo : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Game Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppTheme.terracotta),
                  title: const Text('Resign Game', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Forfeit the match to your opponent', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onResign();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.handshake_outlined, color: AppTheme.greenAccent),
                  title: const Text('Offer Draw', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Propose a mutual tie with your opponent', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _onDraw();
                  },
                ),
                if (!_suddenDeathTriggered && !_gameState.isGameOver && _gameState.phase == GamePhase.movement)
                  ListTile(
                    leading: const Icon(Icons.local_fire_department, color: AppTheme.tigerOrange),
                    title: const Text('Sudden Death Mode', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Begin shrinking board boundary collapse', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () {
                      Navigator.of(context).pop();
                      _triggerSuddenDeath();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: AppTheme.turmeric),
                  title: const Text('Game Rules & Guide', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/rules');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChatModal() {
    final quickMessages = [
      '👋 Hello!',
      '👍 Good luck!',
      '🔥 Great move!',
      '😮 Wow, nice one!',
      '🛡️ Defending well!',
      '🐅 Watch out for tiger!',
      '🐐 Goats unite!',
      '🤝 Good game!',
      '⏱️ Please make a move!',
      '🎉 Well played!',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: AppTheme.tigerOrange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Chat & Reactions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickMessages.map((msg) {
                    return ActionChip(
                      backgroundColor: AppTheme.darkerBg,
                      side: const BorderSide(color: Colors.white12),
                      label: Text(
                        msg,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _triggerCallout('You: $msg');
                        if (_soundEnabled) GameSound.buttonTap.play();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveAbilityBanner() {
    if (_selectedPowerUp == null || _gameState.isGameOver) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.turmeric.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.turmeric),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedPowerUp!.icon} ${_selectedPowerUp!.name} active — tap target on board',
              style: const TextStyle(color: AppTheme.turmeric, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _selectedPowerUp = null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70, fontSize: 11, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbilitiesSheet() {
    if (widget.puzzle != null || _gameState.isGameOver) return;

    final isPlayerTiger = widget.playerRole == PieceType.tiger ||
        (widget.playerRole == null && _gameState.currentTurn == PlayerTurn.tiger);
    final isMyTurn = _isMyTurn;

    final abilities = isPlayerTiger
        ? [PowerUpType.tigerRoar, PowerUpType.superPounce]
        : [PowerUpType.hornShield, PowerUpType.boulder];

    final usedSet = _gameState.usedPowerUps[isPlayerTiger ? PlayerTurn.tiger : PlayerTurn.goat] ?? {};

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.turmeric, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Tactical Abilities',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...abilities.map((pu) {
                  final isUsed = usedSet.contains(pu);
                  final isSelected = _selectedPowerUp == pu;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.turmeric.withValues(alpha: 0.15)
                          : AppTheme.darkerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.turmeric
                            : (isUsed ? Colors.white10 : Colors.white24),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Text(pu.icon, style: const TextStyle(fontSize: 22)),
                      ),
                      title: Text(
                        pu.name,
                        style: TextStyle(
                          color: isUsed ? Colors.white38 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        pu.description,
                        style: TextStyle(
                          color: isUsed ? Colors.white24 : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: (!isMyTurn || isUsed)
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                setState(() {
                                  if (_selectedPowerUp == pu) {
                                    _selectedPowerUp = null;
                                  } else {
                                    _selectedPowerUp = pu;
                                    _showSnackBar('Select target on the board for ${pu.name}');
                                  }
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? AppTheme.terracotta : AppTheme.turmeric,
                          foregroundColor: isSelected ? Colors.white : AppTheme.darkestBg,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        child: Text(isUsed ? 'Used' : (isSelected ? 'Cancel' : 'Use Ability')),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStagnationBanner() {
    if (_gameState.phase != GamePhase.movement || _gameState.isGameOver) {
      return const SizedBox.shrink();
    }
    final movesWithoutCapture = _gameState.movesWithoutCapture;
    if (movesWithoutCapture < 20) return const SizedBox.shrink();

    final remaining = 40 - movesWithoutCapture;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.terracotta.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.terracotta.withValues(alpha: 0.6)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.terracotta, size: 16),
              const SizedBox(width: 6),
              Text(
                '40-Move Rule: $remaining moves left without capture before Draw!',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (!_suddenDeathTriggered)
            InkWell(
              onTap: _triggerSuddenDeath,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.tigerOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Break Stalemate: Collapse 🔥',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLowTimeVignette() {
    if (!_vfxEnabled || !widget.timer.hasLimit || _gameState.isGameOver) {
      return const SizedBox.shrink();
    }

    final isTiger = _gameState.currentTurn == PlayerTurn.tiger;
    final currentTime = isTiger ? _tigerTime : _goatTime;

    if (currentTime.inSeconds > 10 || currentTime.inSeconds <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: ((10 - currentTime.inSeconds) * 0.08).clamp(0.1, 0.8)),
              width: 6,
            ),
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.redAccent.withValues(alpha: ((10 - currentTime.inSeconds) * 0.04).clamp(0.0, 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCallout() {
    if (_calloutText == null) return const SizedBox.shrink();

    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _calloutController,
          builder: (context, child) {
            final value = _calloutController.value;
            final opacity = (1.0 - (value - 0.7).clamp(0.0, 0.3) / 0.3).clamp(0.0, 1.0);
            final scale = (0.7 + 0.4 * Curves.elasticOut.transform(value.clamp(0.0, 0.8) / 0.8)).clamp(0.5, 1.2);
            final translateY = -35.0 * value;

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE86A17), Color(0xFFFF9800)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _calloutText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _wrapWithScreenShake({required Widget child}) {
    if (!_vfxEnabled) return child;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, childWidget) {
        final progress = _shakeController.value;
        if (progress == 0.0 || progress == 1.0) return childWidget!;
        final offset = 6.0 * (1.0 - progress) * (progress * 20 % 2 == 0 ? 1 : -1);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: childWidget,
        );
      },
      child: child,
    );
  }

  void _triggerSuddenDeath() {
    if (_gameState.isGameOver) return;
    _suddenDeathTriggered = true;
    _performCollapseStep();

    _suddenDeathIntervalTimer?.cancel();
    _suddenDeathIntervalTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_gameState.isGameOver) {
        timer.cancel();
        return;
      }
      _performCollapseStep();
    });
  }

  void _performCollapseStep() {
    final allPositions = <Position>[];
    for (int r = 0; r < _level.rows; r++) {
      for (int c = 0; c < _level.cols; c++) {
        final pos = Position(r, c);
        if (_engine.connections.isValidPosition(pos) && !_gameState.collapsedPositions.contains(pos)) {
          allPositions.add(pos);
        }
      }
    }

    // Keep at least the core center positions so the game has a tight final battleground
    final minRemaining = _level == BoardLevel.traditional ? 9 : (_level == BoardLevel.square ? 6 : 4);
    if (allPositions.length <= minRemaining) {
      _suddenDeathIntervalTimer?.cancel();
      return;
    }

    final centerRow = (_level.rows - 1) / 2.0;
    final centerCol = (_level.cols - 1) / 2.0;

    // Calculate distance of each uncollapsed position from the center
    final distMap = <Position, double>{};
    double maxDist = 0;
    for (final p in allPositions) {
      final d = (p.row - centerRow).abs() + (p.col - centerCol).abs();
      distMap[p] = d;
      if (d > maxDist) maxDist = d;
    }

    // Find the outermost positions (within 0.5 of max distance)
    final outerCandidates = allPositions.where((p) => (distMap[p]! - maxDist).abs() <= 0.5).toList();
    outerCandidates.shuffle();

    // Pick 2 to 4 random positions to collapse in this wave
    final countToCollapse = outerCandidates.length <= 4 ? outerCandidates.length : 2 + (DateTime.now().millisecond % 3);
    final collapsingNodes = outerCandidates.take(countToCollapse).toSet();

    if (collapsingNodes.isEmpty) return;

    _collapseStep++;
    setState(() {
      _gameState = _engine.triggerArenaCollapse(_gameState, collapsingNodes);
    });

    if (_isOnline && widget.matchId != null) {
      ref
          .read(multiplayerServiceProvider)
          .updateSuddenDeathCollapse(widget.matchId!, _gameState.collapsedPositions);
    }

    _triggerScreenShake();
    _triggerCallout('🔥 SUDDEN DEATH: COLLAPSE STAGE $_collapseStep! 🔥');
    if (_soundEnabled) GameSound.tigerCapture.play();
    _showSnackBar('🔥 Sudden Death: Outer tiles engulfed in flames! Pieces pushed inward.');
    if (_gameState.isGameOver) {
      _showGameOverDialog();
    }
  }

  /// Bottom bar for puzzle mode: shows progress and a hint button.
  Widget _buildPuzzleFooter() {
    final puzzle = widget.puzzle;
    if (puzzle == null) return const SizedBox.shrink();
    final isSolved = _puzzleSolved;
    final total = puzzle.solution.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isSolved ? Icons.check_circle : Icons.extension,
                color: isSolved ? AppTheme.greenAccent : AppTheme.turmeric,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSolved
                      ? 'Solved! Great job!'
                      : (total == 1
                          ? 'Find the winning move'
                          : 'Find the $total-move solution'),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              if (!isSolved) ...[
                Text(
                  '$_puzzleMoveIndex/$total',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                tooltip: 'Hint',
                icon: const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.turmeric,
                ),
                onPressed: isSolved ? null : () => _showPuzzleHint(puzzle),
              ),
            ],
          ),
          if (!isSolved)
            Container(
              margin: const EdgeInsets.only(top: 6),
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total == 0
                    ? 0
                    : (_puzzleMoveIndex / total).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.greenAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
