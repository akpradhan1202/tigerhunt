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

  // Timer
  Timer? _gameTimer;
  Duration _tigerTime = Duration.zero;
  Duration _goatTime = Duration.zero;

  // Puzzle mode
  int _puzzleMoveIndex = 0;
  bool _puzzleSolved = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _onlineSub?.cancel();
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
    _myPlayerId = null;
    _drawDialogOpen = false;
    _lastDrawOffer = null;
    _drawResolved = false;

    // Initialize audio and play start sound
    AudioService.instance.init();
    GameSound.gameStart.play();

    // Initialize timer
    if (widget.timer.hasLimit) {
      _tigerTime = widget.timer.duration;
      _goatTime = widget.timer.duration;
      _startTimer();
    }

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

    if (match.status == MatchStatus.completed && match.winner != null) {
      setState(() {
        _gameState = _gameState.copyWith(
          winner: match.winner,
          phase: GamePhase.ended,
        );
      });
      _showGameOverDialog();
      return;
    }

    if (match.status == MatchStatus.cancelled) {
      if (!_gameOverHandled) {
        _gameOverHandled = true;
        _showOpponentLeftDialog();
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
  }

  void _showOpponentLeftDialog() {
    _gameTimer?.cancel();
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/play');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenAccent,
            ),
            child: const Text('Back to Home'),
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

  /// Pick the sound for a move: a dramatic roar for captures, a low growl
  /// for tiger movement, and a light blip for goat moves and placements.
  GameSound _soundForMove(Move move) {
    if (move.isCapture) return GameSound.tigerCapture;
    if (move.pieceType == PieceType.tiger) return GameSound.tigerMove;
    return GameSound.goatMove;
  }

  void _executeMove(Move move) {
    if (_isAIThinking) return;
    final matchId = widget.matchId;

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
        // Keep the board on the player's turn so the tactical line can
        // continue without an opponent reply.
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

    setState(() {
      _gameState = _engine.executeMove(_gameState, move);
      _lastMove = move;
      _selectedPosition = null;
      _validMoves = [];
    });

    if (_gameState.isGameOver) {
      _showGameOverDialog();
    } else if (_aiPlayer != null) {
      Future.delayed(const Duration(milliseconds: 200), _makeAIMove);
    }

    // In online mode, push the move to Firestore. The opponent's client
    // replays it from its own stream; our own echo is ignored via _appliedMoves.
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

  void _showGameOverDialog({bool timeOut = false}) {
    if (_gameOverHandled) return;
    _gameOverHandled = true;
    _gameTimer?.cancel();
    final winner = _gameState.winner;
    String title;
    String message;
    String emoji;

    // Determine if player won or lost for sound
    bool playerWon = false;
    if (widget.playerRole == PieceType.tiger && winner == GameWinner.tigers) {
      playerWon = true;
    } else if (widget.playerRole == PieceType.goat && winner == GameWinner.goats) {
      playerWon = true;
    } else if (winner == GameWinner.draw) {
      playerWon = false; // Draw = no win sound
    }

    // Play win/lose sound
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
        message = timeOut
            ? 'Goats ran out of time!'
            : 'The tigers captured ${_gameState.goatsCaptured} goats.';
        emoji = '🐯';
        break;
      case GameWinner.goats:
        title = 'Goats Win!';
        message = timeOut
            ? 'Tigers ran out of time!'
            : 'The goats trapped all tigers!';
        emoji = '🐐';
        break;
      case GameWinner.draw:
        title = 'Draw!';
        message = 'The game ended in a draw.';
        emoji = '🤝';
        break;
      default:
        return;
    }

    // Persist the player's rating/stats. This only affects games against the
    // AI (offline + a difficulty); pass & play and online are ignored inside
    // recordGameResult. Fire-and-forget: the UI reads profileProvider live.
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
              setState(() => _initGame());
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
            onPressed: () {
              Navigator.pop(context);
              if (_isOnline && widget.matchId != null) {
                final winner = widget.playerRole == PieceType.tiger
                    ? GameWinner.goats
                    : GameWinner.tigers;
                ref
                    .read(multiplayerServiceProvider)
                    .completeMatch(matchId: widget.matchId!, winner: winner)
                    .catchError((Object _) {});
              }
              context.go('/play');
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

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700 &&
                constraints.maxWidth > constraints.maxHeight * 0.85;

            if (isWide) {
              return Column(
                children: [
                  // Top bar
                  _buildTopBar(),

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

                          // Right: Sidebar with players, status, and controls
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
                ),

                // Game board
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
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

                // Goats to place indicator
                if (_gameState.phase == GamePhase.placement)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Player (bottom) info bar
                _buildPlayerBar(
                  name: 'You',
                  emoji: isPlayerTiger ? '🐯' : '🐐',
                  isCurrentTurn: isPlayerTiger ? isTigerTurn : !isTigerTurn,
                  time: isPlayerTiger ? _tigerTime : _goatTime,
                  isTop: false,
                  capturedCount: isPlayerTiger ? _gameState.goatsCaptured : 0,
                ),

                // Bottom controls
                _buildBottomControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppTheme.darkerBg,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.puzzle != null
                ? () => Navigator.of(context).pop()
                : _onResign,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Text(
                  widget.puzzle?.title ?? _level.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.timer.hasLimit) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 16, color: Colors.white24),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.timer.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          if (_isAIThinking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.greenAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.greenAccent),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: TextStyle(color: AppTheme.greenAccent, fontSize: 13),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(
              _showMoveHints ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showMoveHints ? AppTheme.turmeric : Colors.white54,
            ),
            onPressed: () {
              if (_soundEnabled) GameSound.buttonTap.play();
              setState(() => _showMoveHints = !_showMoveHints);
            },
          ),
          IconButton(
            icon: Icon(
              _soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: _soundEnabled ? AppTheme.greenAccent : Colors.white54,
            ),
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
  }) {
    final hasTimer = widget.timer.hasLimit;
    final isLowTime = time.inSeconds <= 30 && hasTimer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentTurn ? AppTheme.cardDark : AppTheme.darkerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentTurn ? AppTheme.greenAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentTurn
                  ? AppTheme.greenAccent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),

          // Name and captured
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                if (capturedCount > 0)
                  Row(
                    children: List.generate(
                      capturedCount,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(
                          emoji == '🐯' ? '🐐' : '🐯',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Timer
          if (hasTimer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isLowTime
                    ? AppTheme.terracotta.withValues(alpha: 0.3)
                    : (isCurrentTurn ? AppTheme.greenAccent : Colors.white12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatTime(time),
                style: TextStyle(
                  color: isLowTime
                      ? AppTheme.terracotta
                      : (isCurrentTurn ? Colors.white : Colors.white70),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(Icons.flag_outlined, 'Resign', _onResign),
          const SizedBox(width: 16),
          _buildControlButton(Icons.handshake_outlined, 'Draw', _onDraw),
          const SizedBox(width: 16),
          _buildControlButton(Icons.undo, 'Undo', canUndo ? _onUndo : null),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback? onTap) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isEnabled ? Colors.white70 : Colors.white30, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white70 : Colors.white30,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
