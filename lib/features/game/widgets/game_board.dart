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
                  clipBehavior: Clip.none,
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

  /// Convert board position to screen coordinates
  Offset _positionToOffset(Position pos, double boardSize) {
    final cellSize = boardSize / (level.cols - 1);

    if (level == BoardLevel.traditional) {
      // For traditional board, the grid is offset by 1 cell to make room for triangles
      // The grid spans from (0,0) to (4,4) in logical coordinates
      // Triangle apexes are at (-1,2), (5,2), (2,-1), (2,5)
      // Actual cell size for traditional is boardSize/6 (to fit -1 to 5 = 6 units)
      final traditionalCellSize = boardSize / 6;
      // Offset everything by 1 cell
      return Offset(
        (pos.col + 1) * traditionalCellSize,
        (pos.row + 1) * traditionalCellSize,
      );
    }

    return Offset(pos.col * cellSize, pos.row * cellSize);
  }

  Widget _buildMoveIndicator(Move move, double boardSize) {
    final offset = _positionToOffset(move.to, boardSize);
    final isCapture = move.isCapture;

    return Positioned(
      left: offset.dx - 15,
      top: offset.dy - 15,
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
    final offset = _positionToOffset(piece.position, boardSize);

    final isSelected = selectedPosition == piece.position;
    final isTiger = piece.type == PieceType.tiger;

    return AnimatedPositioned(
      duration: GameStyles.moveDuration,
      curve: Curves.easeOutCubic,
      left: offset.dx - GameStyles.pieceSize / 2,
      top: offset.dy - GameStyles.pieceSize / 2,
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

    return positions.map((pos) {
      final offset = _positionToOffset(pos, boardSize);
      final hasPiece = gameState.getPieceAt(pos) != null;

      if (hasPiece) return const SizedBox.shrink();

      return Positioned(
        left: offset.dx - 20,
        top: offset.dy - 20,
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
    // For traditional board, we need 6 units total (-1 to 5)
    // Recalculate cellSize to fit triangles
    final traditionalCellSize = size.width / 6;

    final linePaint = Paint()
      ..color = AppTheme.boardLine
      ..strokeWidth = GameStyles.lineWidth
      ..strokeCap = StrokeCap.round;

    // Helper to convert logical coords to screen coords
    // Logical coords: main grid is 0-4, triangles extend to -1 and 5
    // Screen coords: shifted so -1 maps to 0
    Offset pos(double col, double row) => Offset(
      (col + 1) * traditionalCellSize,
      (row + 1) * traditionalCellSize,
    );

    // Draw main 5x5 grid
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        pos(0, i.toDouble()),
        pos(4, i.toDouble()),
        linePaint,
      );
      canvas.drawLine(
        pos(i.toDouble(), 0),
        pos(i.toDouble(), 4),
        linePaint,
      );
    }

    // Draw diagonals on the main grid
    final diagonalPaint = Paint()
      ..color = AppTheme.boardLine.withOpacity(0.8)
      ..strokeWidth = GameStyles.lineWidth * 0.8
      ..strokeCap = StrokeCap.round;

    // Main corner-to-corner diagonals
    canvas.drawLine(pos(0, 0), pos(4, 4), diagonalPaint);
    canvas.drawLine(pos(4, 0), pos(0, 4), diagonalPaint);

    // Center diagonals (forming X pattern from center to edges)
    canvas.drawLine(pos(0, 2), pos(2, 0), diagonalPaint);
    canvas.drawLine(pos(4, 2), pos(2, 0), diagonalPaint);
    canvas.drawLine(pos(0, 2), pos(2, 4), diagonalPaint);
    canvas.drawLine(pos(4, 2), pos(2, 4), diagonalPaint);

    // ========== TRIANGLE EXTENSIONS ==========
    // TOP TRIANGLE - apex extends upward
    final topApex = pos(2, -1);
    canvas.drawLine(pos(1, 0), topApex, linePaint);
    canvas.drawLine(pos(3, 0), topApex, linePaint);
    canvas.drawLine(pos(2, 0), topApex, linePaint);

    // BOTTOM TRIANGLE - apex extends downward
    final bottomApex = pos(2, 5);
    canvas.drawLine(pos(1, 4), bottomApex, linePaint);
    canvas.drawLine(pos(3, 4), bottomApex, linePaint);
    canvas.drawLine(pos(2, 4), bottomApex, linePaint);

    // LEFT TRIANGLE - apex extends leftward
    final leftApex = pos(-1, 2);
    canvas.drawLine(pos(0, 1), leftApex, linePaint);
    canvas.drawLine(pos(0, 3), leftApex, linePaint);
    canvas.drawLine(pos(0, 2), leftApex, linePaint);

    // RIGHT TRIANGLE - apex extends rightward
    final rightApex = pos(5, 2);
    canvas.drawLine(pos(4, 1), rightApex, linePaint);
    canvas.drawLine(pos(4, 3), rightApex, linePaint);
    canvas.drawLine(pos(4, 2), rightApex, linePaint);
  }

  void _drawIntersectionDots(Canvas canvas, Size size, double cellSize) {
    final dotPaint = Paint()
      ..color = AppTheme.boardDot
      ..style = PaintingStyle.fill;

    final connections = BoardConnections(level);

    if (level == BoardLevel.traditional) {
      // For traditional board, use the same scaling as the board drawing
      final traditionalCellSize = size.width / 6;
      for (final pos in connections.allPositions) {
        canvas.drawCircle(
          Offset(
            (pos.col + 1) * traditionalCellSize,
            (pos.row + 1) * traditionalCellSize,
          ),
          GameStyles.dotRadius,
          dotPaint,
        );
      }
    } else {
      for (final pos in connections.allPositions) {
        canvas.drawCircle(
          Offset(pos.col * cellSize, pos.row * cellSize),
          GameStyles.dotRadius,
          dotPaint,
        );
      }
    }
  }

  void _drawLastMoveHighlight(Canvas canvas, double cellSize) {
    if (lastMove == null) return;

    final highlightPaint = Paint()
      ..color = AppTheme.turmeric.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // For traditional board, use adjusted cell size
    final effectiveCellSize = level == BoardLevel.traditional
        ? cellSize * 4 / 6  // Scale down since traditional uses 6 units
        : cellSize;
    final offset = level == BoardLevel.traditional ? effectiveCellSize * 1.5 : 0.0;

    Offset posToOffset(Position pos) {
      if (level == BoardLevel.traditional) {
        final traditionalCellSize = cellSize * 4 / 6;
        return Offset(
          (pos.col + 1) * traditionalCellSize,
          (pos.row + 1) * traditionalCellSize,
        );
      }
      return Offset(pos.col * cellSize, pos.row * cellSize);
    }

    // Highlight from position
    if (lastMove!.from != const Position(-1, -1)) {
      canvas.drawCircle(
        posToOffset(lastMove!.from),
        GameStyles.dotRadius * 2,
        highlightPaint,
      );
    }

    // Highlight to position
    canvas.drawCircle(
      posToOffset(lastMove!.to),
      GameStyles.dotRadius * 2,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.lastMove != lastMove || oldDelegate.level != level;
  }
}
