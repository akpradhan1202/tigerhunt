import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/game_models.dart';
import '../models/game_state.dart';
import '../models/game_engine.dart';
import '../models/ai_engine.dart';
import '../widgets/game_board.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/captured_pieces.dart';
import '../widgets/game_controls.dart';

class GameScreen extends ConsumerStatefulWidget {
  final BoardLevel level;
  final GameMode mode;
  final GameTimer timer;
  final AIDifficulty? aiDifficulty;
  final PieceType? playerRole; // For AI games

  const GameScreen({
    super.key,
    required this.level,
    required this.mode,
    required this.timer,
    this.aiDifficulty,
    this.playerRole,
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

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _gameState = GameState.initial(widget.level, timer: widget.timer);
    _engine = GameEngine(widget.level);
    _selectedPosition = null;
    _validMoves = [];
    _lastMove = null;
    _isAIThinking = false;

    // Setup AI if playing against bots
    if (widget.aiDifficulty != null) {
      // Determine which side AI plays
      final aiPlaysAs = widget.playerRole == PieceType.goat
          ? PieceType.tiger
          : PieceType.goat;

      _aiPlayer = AIPlayer(
        gameEngine: _engine,
        difficulty: widget.aiDifficulty!,
        playingAs: aiPlaysAs,
      );

      // If AI plays goats (goes first), make AI move
      if (aiPlaysAs == PieceType.goat) {
        Future.delayed(const Duration(milliseconds: 500), _makeAIMove);
      }
    }
  }

  Future<void> _makeAIMove() async {
    if (_aiPlayer == null || _gameState.isGameOver || _isAIThinking) return;

    // Check if it's AI's turn
    final isAITurn = (_aiPlayer!.playingAs == PieceType.tiger &&
                      _gameState.currentTurn == PlayerTurn.tiger) ||
                     (_aiPlayer!.playingAs == PieceType.goat &&
                      _gameState.currentTurn == PlayerTurn.goat);

    if (!isAITurn) return;

    setState(() => _isAIThinking = true);

    // Small delay for natural feel
    await Future.delayed(const Duration(milliseconds: 300));

    final move = await _aiPlayer!.getMove(_gameState);

    if (move != null && mounted) {
      setState(() {
        _gameState = _engine.executeMove(_gameState, move);
        _lastMove = move;
        _selectedPosition = null;
        _validMoves = [];
        _isAIThinking = false;
      });

      // Check for game over
      if (_gameState.isGameOver) {
        _showGameOverDialog();
      }
    } else if (mounted) {
      setState(() => _isAIThinking = false);
    }
  }

  void _onPositionTap(Position pos) {
    if (_gameState.isGameOver) return;
    if (_isAIThinking) return; // Block input during AI turn

    // Check if it's AI's turn - block player input
    if (_aiPlayer != null) {
      final isAITurn = (_aiPlayer!.playingAs == PieceType.tiger &&
                        _gameState.currentTurn == PlayerTurn.tiger) ||
                       (_aiPlayer!.playingAs == PieceType.goat &&
                        _gameState.currentTurn == PlayerTurn.goat);
      if (isAITurn) return;
    }

    final piece = _gameState.getPieceAt(pos);

    // If no piece selected
    if (_selectedPosition == null) {
      // During placement phase, goats tap empty positions
      if (_gameState.phase == GamePhase.placement &&
          _gameState.currentTurn == PlayerTurn.goat) {
        if (_gameState.isPositionEmpty(pos)) {
          _placeGoat(pos);
        }
        return;
      }

      // Select a piece if it belongs to current player
      if (piece != null) {
        final isTigerTurn = _gameState.currentTurn == PlayerTurn.tiger;
        final isGoatTurn = _gameState.currentTurn == PlayerTurn.goat;

        if ((isTigerTurn && piece.type == PieceType.tiger) ||
            (isGoatTurn && piece.type == PieceType.goat)) {
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
      // A piece is already selected
      // Check if tapping on a valid move destination
      final move = _validMoves.firstWhere(
        (m) => m.to == pos,
        orElse: () => Move(
          from: const Position(-1, -1),
          to: const Position(-1, -1),
          pieceType: PieceType.goat,
        ),
      );

      if (move.from != const Position(-1, -1)) {
        _executeMove(move);
      } else if (piece != null && piece.position != _selectedPosition) {
        // Select different piece
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
        // Deselect
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

  void _executeMove(Move move) {
    // Don't allow moves while AI is thinking
    if (_isAIThinking) return;

    setState(() {
      _gameState = _engine.executeMove(_gameState, move);
      _lastMove = move;
      _selectedPosition = null;
      _validMoves = [];
    });

    // Play sound
    if (_soundEnabled) {
      // TODO: Play move/capture sound
    }

    // Check for game over
    if (_gameState.isGameOver) {
      _showGameOverDialog();
    } else if (_aiPlayer != null) {
      // Trigger AI move after player moves
      Future.delayed(const Duration(milliseconds: 200), _makeAIMove);
    }
  }

  void _showGameOverDialog() {
    final winner = _gameState.winner;
    String title;
    String message;
    String emoji;

    switch (winner) {
      case GameWinner.tigers:
        title = 'Tigers Win!';
        message = 'The tigers captured ${_gameState.goatsCaptured} goats.';
        emoji = '🐯';
        break;
      case GameWinner.goats:
        title = 'Goats Win!';
        message = 'The goats trapped all tigers!';
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.charcoal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.charcoal.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _initGame());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _onResign() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.parchment,
      appBar: AppBar(
        backgroundColor: AppTheme.parchment,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _onResign(),
        ),
        title: Text(
          widget.level.name,
          style: const TextStyle(
            color: AppTheme.charcoal,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMoveHints ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showMoveHints ? AppTheme.turmeric : AppTheme.charcoal,
            ),
            onPressed: () => setState(() => _showMoveHints = !_showMoveHints),
            tooltip: 'Toggle hints',
          ),
          IconButton(
            icon: Icon(
              _soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: AppTheme.charcoal,
            ),
            onPressed: () => setState(() => _soundEnabled = !_soundEnabled),
            tooltip: 'Toggle sound',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Opponent info (Tigers or timer opponent)
            PlayerInfoBar(
              name: 'Tigers',
              emoji: '🐯',
              isCurrentTurn: _gameState.currentTurn == PlayerTurn.tiger,
              timeRemaining: _gameState.tigerTimeRemaining,
              capturedCount: _gameState.goatsCaptured,
              capturedEmoji: '🐐',
            ),

            const SizedBox(height: 8),

            // Captured goats display
            if (_gameState.goatsCaptured > 0)
              CapturedPieces(
                count: _gameState.goatsCaptured,
                pieceType: PieceType.goat,
              ),

            // Game board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GameBoard(
                    level: widget.level,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🐐', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '${_gameState.goatsToPlace} goats left to place',
                        style: const TextStyle(
                          color: AppTheme.forestGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Player info (Goats)
            PlayerInfoBar(
              name: 'Goats',
              emoji: '🐐',
              isCurrentTurn: _gameState.currentTurn == PlayerTurn.goat,
              timeRemaining: _gameState.goatTimeRemaining,
              capturedCount: 0,
              isPlayer: true,
            ),

            const SizedBox(height: 8),

            // Game controls
            GameControls(
              onResign: _onResign,
              onOfferDraw: () {},
              onUndo: null, // TODO: Implement undo
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
