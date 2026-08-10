import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/game_models.dart';
import '../models/game_state.dart';
import '../models/board_connections.dart';

/// The main game board widget with traditional Indian styling
class GameBoard extends StatelessWidget {
  final BoardLevel level;
  final GameState gameState;
  final Position? selectedPosition;
  final List<Move> validMoves;
  final Move? lastMove;
  final bool showHints;
  final Function(Position) onPositionTap;

  const GameBoard({
    super.key,
    required this.level,
    required this.gameState,
    this.selectedPosition,
    required this.validMoves,
    this.lastMove,
    this.showHints = true,
    required this.onPositionTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: GameStyles.boardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(GameStyles.boardPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardSize = constraints.maxWidth;
              return CustomPaint(
                size: Size(boardSize, boardSize),
                painter: _BoardPainter(
                  level: level,
                  lastMove: lastMove,
                ),
                child: Stack(
                  children: [
                    // Valid move indicators
                    if (showHints)
                      ...validMoves.map((move) => _buildMoveIndicator(
                            move,
                            boardSize,
                          )),

                    // Pieces
                    ...gameState.pieces
                        .where((p) => !p.isCaptured)
                        .map((piece) => _buildPiece(
                              piece,
                              boardSize,
                            )),

                    // Touch targets for all positions
                    ..._buildTouchTargets(boardSize),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMoveIndicator(Move move, double boardSize) {
    final cellSize = boardSize / (level.cols - 1);
    final x = move.to.col * cellSize;
    final y = move.to.row * cellSize;

    final isCapture = move.isCapture;

    return Positioned(
      left: x - 15,
      top: y - 15,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCapture
              ? AppTheme.highlightCapture
              : AppTheme.highlightMove,
          border: isCapture
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
              : null,
        ),
        child: isCapture
            ? const Icon(
                Icons.close,
                color: Colors.red,
                size: 18,
              )
            : null,
      ),
    );
  }

  Widget _buildPiece(Piece piece, double boardSize) {
    final cellSize = boardSize / (level.cols - 1);
    final x = piece.position.col * cellSize;
    final y = piece.position.row * cellSize;

    final isSelected = selectedPosition == piece.position;
    final isTiger = piece.type == PieceType.tiger;

    return AnimatedPositioned(
      duration: GameStyles.moveDuration,
      curve: Curves.easeOutCubic,
      left: x - GameStyles.pieceSize / 2,
      top: y - GameStyles.pieceSize / 2,
      child: GestureDetector(
        onTap: () => onPositionTap(piece.position),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: GameStyles.pieceSize,
          height: GameStyles.pieceSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTiger ? AppTheme.tigerOrange : AppTheme.goatWhite,
            border: Border.all(
              color: isSelected
                  ? AppTheme.peacockBlue
                  : (isTiger ? AppTheme.terracotta : AppTheme.goatGray),
              width: isSelected ? 4 : GameStyles.pieceBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.peacockBlue.withOpacity(0.5)
                    : Colors.black.withOpacity(0.3),
                blurRadius: isSelected ? 12 : 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isTiger ? '🐯' : '🐐',
              style: TextStyle(
                fontSize: isTiger ? 26 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTouchTargets(double boardSize) {
    final connections = BoardConnections(level);
    final positions = connections.allPositions;
    final cellSize = boardSize / (level.cols - 1);

    return positions.map((pos) {
      final x = pos.col * cellSize;
      final y = pos.row * cellSize;
      final hasPiece = gameState.getPieceAt(pos) != null;

      if (hasPiece) return const SizedBox.shrink();

      return Positioned(
        left: x - 20,
        top: y - 20,
        child: GestureDetector(
          onTap: () => onPositionTap(pos),
          child: Container(
            width: 40,
            height: 40,
            color: Colors.transparent,
          ),
        ),
      );
    }).toList();
  }
}

/// Custom painter for the game board lines
class _BoardPainter extends CustomPainter {
  final BoardLevel level;
  final Move? lastMove;

  _BoardPainter({
    required this.level,
    this.lastMove,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / (level.cols - 1);

    // Draw decorative border pattern
    _drawBorderPattern(canvas, size);

    // Draw board based on level
    switch (level) {
      case BoardLevel.pyramid:
        _drawPyramidBoard(canvas, size, cellSize);
        break;
      case BoardLevel.square:
        _drawSquareBoard(canvas, size, cellSize);
        break;
      case BoardLevel.traditional:
        _drawTraditionalBoard(canvas, size, cellSize);
        break;
    }

    // Draw intersection dots
    _drawIntersectionDots(canvas, size, cellSize);

    // Highlight last move
    if (lastMove != null) {
      _drawLastMoveHighlight(canvas, cellSize);
    }
  }

  void _drawBorderPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.henna.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw corner decorations
    const cornerSize = 15.0;
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    for (final corner in corners) {
      final path = Path();
      final isLeft = corner.dx == 0;
      final isTop = corner.dy == 0;

      path.moveTo(
        corner.dx + (isLeft ? cornerSize : -cornerSize),
        corner.dy,
      );
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(
        corner.dx,
        corner.dy + (isTop ? cornerSize : -cornerSize),
      );

      canvas.drawPath(path, paint);
    }
  }

  void _drawPyramidBoard(Canvas canvas, Size size, double cellSize) {
    final linePaint = Paint()
      ..color = AppTheme.boardLine
      ..strokeWidth = GameStyles.lineWidth
      ..strokeCap = StrokeCap.round;

    // Define pyramid positions
    // Row 0: (0,2) - apex
    // Row 1: (1,1), (1,3)
    // Row 2: (2,0), (2,2), (2,4)
    // Row 3: full row (3,0-4)
    // Row 4: full row (4,0-4)

    // Draw connections
    // Apex to row 1
    canvas.drawLine(
      Offset(2 * cellSize, 0),
      Offset(1 * cellSize, 1 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(2 * cellSize, 0),
      Offset(3 * cellSize, 1 * cellSize),
      linePaint,
    );

    // Row 1 horizontal
    canvas.drawLine(
      Offset(1 * cellSize, 1 * cellSize),
      Offset(3 * cellSize, 1 * cellSize),
      linePaint,
    );

    // Row 1 to row 2
    canvas.drawLine(
      Offset(1 * cellSize, 1 * cellSize),
      Offset(0, 2 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(1 * cellSize, 1 * cellSize),
      Offset(2 * cellSize, 2 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(3 * cellSize, 1 * cellSize),
      Offset(2 * cellSize, 2 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(3 * cellSize, 1 * cellSize),
      Offset(4 * cellSize, 2 * cellSize),
      linePaint,
    );

    // Row 2 horizontal
    canvas.drawLine(
      Offset(0, 2 * cellSize),
      Offset(4 * cellSize, 2 * cellSize),
      linePaint,
    );

    // Row 2 to row 3
    for (int col = 0; col <= 4; col += 2) {
      // Vertical
      canvas.drawLine(
        Offset(col * cellSize, 2 * cellSize),
        Offset(col * cellSize, 3 * cellSize),
        linePaint,
      );
    }
    // Diagonals
    canvas.drawLine(
      Offset(0, 2 * cellSize),
      Offset(1 * cellSize, 3 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(2 * cellSize, 2 * cellSize),
      Offset(1 * cellSize, 3 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(2 * cellSize, 2 * cellSize),
      Offset(3 * cellSize, 3 * cellSize),
      linePaint,
    );
    canvas.drawLine(
      Offset(4 * cellSize, 2 * cellSize),
      Offset(3 * cellSize, 3 * cellSize),
      linePaint,
    );

    // Row 3 and 4 - full grid
    for (int row = 3; row <= 4; row++) {
      canvas.drawLine(
        Offset(0, row * cellSize),
        Offset(4 * cellSize, row * cellSize),
        linePaint,
      );
    }
    for (int col = 0; col <= 4; col++) {
      canvas.drawLine(
        Offset(col * cellSize, 3 * cellSize),
        Offset(col * cellSize, 4 * cellSize),
        linePaint,
      );
    }
  }

  void _drawSquareBoard(Canvas canvas, Size size, double cellSize) {
    final linePaint = Paint()
      ..color = AppTheme.boardLine
      ..strokeWidth = GameStyles.lineWidth
      ..strokeCap = StrokeCap.round;

    // Draw grid lines
    for (int i = 0; i < 5; i++) {
      // Horizontal
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(4 * cellSize, i * cellSize),
        linePaint,
      );
      // Vertical
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, 4 * cellSize),
        linePaint,
      );
    }

    // Draw diagonals (only where row+col is even)
    final diagonalPaint = Paint()
      ..color = AppTheme.boardLine.withOpacity(0.7)
      ..strokeWidth = GameStyles.lineWidth * 0.8
      ..strokeCap = StrokeCap.round;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if ((row + col) % 2 == 0) {
          // Diagonal down-right
          canvas.drawLine(
            Offset(col * cellSize, row * cellSize),
            Offset((col + 1) * cellSize, (row + 1) * cellSize),
            diagonalPaint,
          );
        } else {
          // Diagonal down-left
          canvas.drawLine(
            Offset((col + 1) * cellSize, row * cellSize),
            Offset(col * cellSize, (row + 1) * cellSize),
            diagonalPaint,
          );
        }
      }
    }
  }

  void _drawTraditionalBoard(Canvas canvas, Size size, double cellSize) {
    final linePaint = Paint()
      ..color = AppTheme.boardLine
      ..strokeWidth = GameStyles.lineWidth
      ..strokeCap = StrokeCap.round;

    // Draw main grid
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(4 * cellSize, i * cellSize),
        linePaint,
      );
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, 4 * cellSize),
        linePaint,
      );
    }

    // Draw diagonals (traditional pattern)
    final diagonalPaint = Paint()
      ..color = AppTheme.boardLine.withOpacity(0.8)
      ..strokeWidth = GameStyles.lineWidth * 0.8
      ..strokeCap = StrokeCap.round;

    // Main diagonals
    canvas.drawLine(
      Offset(0, 0),
      Offset(4 * cellSize, 4 * cellSize),
      diagonalPaint,
    );
    canvas.drawLine(
      Offset(4 * cellSize, 0),
      Offset(0, 4 * cellSize),
      diagonalPaint,
    );

    // Triangle diagonals
    // Top triangle
    canvas.drawLine(
      Offset(0, 2 * cellSize),
      Offset(2 * cellSize, 0),
      diagonalPaint,
    );
    canvas.drawLine(
      Offset(4 * cellSize, 2 * cellSize),
      Offset(2 * cellSize, 0),
      diagonalPaint,
    );
    // Bottom triangle
    canvas.drawLine(
      Offset(0, 2 * cellSize),
      Offset(2 * cellSize, 4 * cellSize),
      diagonalPaint,
    );
    canvas.drawLine(
      Offset(4 * cellSize, 2 * cellSize),
      Offset(2 * cellSize, 4 * cellSize),
      diagonalPaint,
    );
    // Left triangle
    canvas.drawLine(
      Offset(2 * cellSize, 0),
      Offset(0, 2 * cellSize),
      diagonalPaint,
    );
    canvas.drawLine(
      Offset(2 * cellSize, 4 * cellSize),
      Offset(0, 2 * cellSize),
      diagonalPaint,
    );
    // Right triangle
    canvas.drawLine(
      Offset(2 * cellSize, 0),
      Offset(4 * cellSize, 2 * cellSize),
      diagonalPaint,
    );
    canvas.drawLine(
      Offset(2 * cellSize, 4 * cellSize),
      Offset(4 * cellSize, 2 * cellSize),
      diagonalPaint,
    );
  }

  void _drawIntersectionDots(Canvas canvas, Size size, double cellSize) {
    final dotPaint = Paint()
      ..color = AppTheme.boardDot
      ..style = PaintingStyle.fill;

    final connections = BoardConnections(level);
    for (final pos in connections.allPositions) {
      canvas.drawCircle(
        Offset(pos.col * cellSize, pos.row * cellSize),
        GameStyles.dotRadius,
        dotPaint,
      );
    }
  }

  void _drawLastMoveHighlight(Canvas canvas, double cellSize) {
    if (lastMove == null) return;

    final highlightPaint = Paint()
      ..color = AppTheme.turmeric.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Highlight from position
    if (lastMove!.from != const Position(-1, -1)) {
      canvas.drawCircle(
        Offset(lastMove!.from.col * cellSize, lastMove!.from.row * cellSize),
        GameStyles.dotRadius * 2,
        highlightPaint,
      );
    }

    // Highlight to position
    canvas.drawCircle(
      Offset(lastMove!.to.col * cellSize, lastMove!.to.row * cellSize),
      GameStyles.dotRadius * 2,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.lastMove != lastMove || oldDelegate.level != level;
  }
}
