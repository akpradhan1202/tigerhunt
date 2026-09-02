import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../models/game_state.dart';
import '../models/board_connections.dart';

/// Maps a Traditional-board position to its pixel offset. The 5x5 grid
/// occupies the central half of the canvas (0.25..0.75) and the four
/// fan-shaped extensions spread outward cleanly without overlapping pieces.
Offset traditionalPositionOffset(Position pos, double boardSize) {
  // Central 5x5 grid (normalized 0.25..0.75).
  if (pos.row >= 0 && pos.row <= 4 && pos.col >= 0 && pos.col <= 4) {
    return Offset(
      (0.25 + pos.col * 0.125) * boardSize,
      (0.25 + pos.row * 0.125) * boardSize,
    );
  }

  // Top fan: outer row at y=0.035 (x: 0.30, 0.50, 0.70), inner row at
  // y=0.14 (x: 0.38, 0.50, 0.62); hub is grid (0,2) at (0.50, 0.25).
  if (pos.row == -1 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.38 + (pos.col - 1) * 0.12) * boardSize, 0.14 * boardSize);
  }
  if (pos.row == -2 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.30 + (pos.col - 1) * 0.20) * boardSize, 0.035 * boardSize);
  }

  // Bottom fan (mirror of the top fan).
  if (pos.row == 5 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.38 + (pos.col - 1) * 0.12) * boardSize, 0.86 * boardSize);
  }
  if (pos.row == 6 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.30 + (pos.col - 1) * 0.20) * boardSize, 0.965 * boardSize);
  }

  // Left fan (mirror of the top fan, rotated).
  if (pos.col == -1 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.14 * boardSize, (0.38 + (pos.row - 1) * 0.12) * boardSize);
  }
  if (pos.col == -2 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.035 * boardSize, (0.30 + (pos.row - 1) * 0.20) * boardSize);
  }

  // Right fan (mirror of the left fan).
  if (pos.col == 5 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.86 * boardSize, (0.38 + (pos.row - 1) * 0.12) * boardSize);
  }
  if (pos.col == 6 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.965 * boardSize, (0.30 + (pos.row - 1) * 0.20) * boardSize);
  }

  return Offset.zero;
}

/// All line segments of the Traditional board as (from, to) position pairs,
/// each edge listed once (from its lexicographically smaller end). This is
/// the classic square Bagh-Chal pattern: the 5x5 grid, the main diagonals,
/// the inner diamond, and the four side triangles.
List<(Position, Position)> traditionalBoardSegments() {
  final connections = BoardConnections(BoardLevel.traditional);
  final segments = <(Position, Position)>[];
  for (final pos in connections.allPositions) {
    for (final neighbor in connections.getNeighbors(pos)) {
      final fromSmaller = pos.row < neighbor.row ||
          (pos.row == neighbor.row && pos.col < neighbor.col);
      if (!fromSmaller) continue;
      segments.add((pos, neighbor));
    }
  }
  return segments;
}

/// The main game board widget
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
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5DC),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            // Traditional layout has extensions that already range from 0.035 to 0.965,
            // so a tight 3% margin maximizes the playable area.
            final margin = level == BoardLevel.traditional ? size * 0.03 : size * 0.06;
            final boardSize = size - (margin * 2);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final local = details.localPosition;
                final boardOffset = Offset(local.dx - margin, local.dy - margin);
                final tappedPos = _findNearestPosition(boardOffset, boardSize);
                if (tappedPos != null) {
                  onPositionTap(tappedPos);
                }
              },
              child: Padding(
                padding: EdgeInsets.all(margin),
                child: CustomPaint(
                  size: Size(boardSize, boardSize),
                  painter: _BoardPainter(level: level),
                  child: IgnorePointer(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (showHints)
                          ...validMoves.map((move) => _buildMoveIndicator(move, boardSize)),
                        ..._buildCollapsedNodes(boardSize),
                        ..._buildBoulders(boardSize),
                        ...gameState.pieces
                            .where((p) => !p.isCaptured)
                            .map((piece) => _buildPiece(piece, boardSize)),
                      ],
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

  Position? _findNearestPosition(Offset offset, double boardSize) {
    final connections = BoardConnections(level);
    Position? nearest;
    double minDistance = double.infinity;
    final snapRadius = (boardSize / (level == BoardLevel.traditional ? 9.0 : 5.0)).clamp(40.0, 60.0);

    for (final pos in connections.allPositions) {
      final posOffset = _positionToOffset(pos, boardSize);
      final distance = (posOffset - offset).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearest = pos;
      }
    }

    if (minDistance <= snapRadius && nearest != null) {
      return nearest;
    }
    return null;
  }

  Offset _positionToOffset(Position pos, double boardSize) {
    if (level == BoardLevel.traditional) {
      return traditionalPositionOffset(pos, boardSize);
    }
    final cellSize = boardSize / 4;
    return Offset(pos.col * cellSize, pos.row * cellSize);
  }

  Iterable<Widget> _buildCollapsedNodes(double boardSize) {
    final nodeSize = (boardSize / (level == BoardLevel.traditional ? 11.5 : 7.0)).clamp(22.0, 38.0);
    return gameState.collapsedPositions.map((pos) {
      final offset = _positionToOffset(pos, boardSize);
      return Positioned(
        left: offset.dx - nodeSize / 2,
        top: offset.dy - nodeSize / 2,
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.deepOrange.withValues(alpha: 0.85),
                Colors.red.shade900.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.4),
              ],
            ),
            border: Border.all(color: Colors.amberAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrangeAccent.withValues(alpha: 0.8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '🔥',
              style: TextStyle(fontSize: (nodeSize * 0.58).clamp(12.0, 20.0)),
            ),
          ),
        ),
      );
    });
  }

  Iterable<Widget> _buildBoulders(double boardSize) {
    final boulderSize = (boardSize / (level == BoardLevel.traditional ? 12.0 : 7.5)).clamp(20.0, 36.0);
    return gameState.activeEffects
        .where((e) => e.type == PowerUpType.boulder)
        .map((effect) {
      final offset = _positionToOffset(effect.targetPosition, boardSize);
      return Positioned(
        left: offset.dx - boulderSize / 2,
        top: offset.dy - boulderSize / 2,
        child: Container(
          width: boulderSize,
          height: boulderSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.brown.shade800,
            border: Border.all(color: Colors.amber.shade700, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text('🪨', style: TextStyle(fontSize: 14)),
          ),
        ),
      );
    });
  }

  Widget _buildMoveIndicator(Move move, double boardSize) {
    final offset = _positionToOffset(move.to, boardSize);
    final indicatorSize = (boardSize / (level == BoardLevel.traditional ? 20.0 : 14.0)).clamp(14.0, 24.0);
    return Positioned(
      left: offset.dx - indicatorSize / 2,
      top: offset.dy - indicatorSize / 2,
      child: Container(
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: move.isCapture
              ? Colors.red.withValues(alpha: 0.6)
              : Colors.green.withValues(alpha: 0.6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPiece(Piece piece, double boardSize) {
    final offset = _positionToOffset(piece.position, boardSize);
    final isSelected = selectedPosition == piece.position;
    final isTiger = piece.type == PieceType.tiger;
    final isShielded = gameState.isGoatShielded(piece.position);
    final isStunned = gameState.isGoatStunned(piece.position);
    final pieceSize = boardSize / (level == BoardLevel.traditional ? 12.5 : 7.0);
    final hitSize = (pieceSize * 1.5).clamp(44.0, 56.0);

    return AnimatedPositioned(
      key: ValueKey(piece.id),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: offset.dx - hitSize / 2,
      top: offset.dy - hitSize / 2,
      child: GestureDetector(
        onTap: () => onPositionTap(piece.position),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: hitSize,
          height: hitSize,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: pieceSize,
                height: pieceSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTiger ? const Color(0xFFE86A17) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Colors.green
                        : (isShielded
                            ? Colors.amberAccent
                            : isStunned
                                ? Colors.cyanAccent
                                : (isTiger ? const Color(0xFFB5510D) : const Color(0xFF333333))),
                    width: (isSelected || isShielded || isStunned) ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isShielded
                          ? Colors.amber.withValues(alpha: 0.8)
                          : (isStunned
                              ? Colors.cyan.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.35)),
                      blurRadius: (isShielded || isStunned) ? 8 : 4,
                      offset: const Offset(1.5, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isTiger ? '🐯' : '🐐',
                    style: TextStyle(fontSize: pieceSize * 0.56),
                  ),
                ),
              ),
              if (isShielded)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🛡️', style: TextStyle(fontSize: 9)),
                  ),
                ),
              if (isStunned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('❄️', style: TextStyle(fontSize: 9)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final BoardLevel level;

  _BoardPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 4;

    final linePaint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    switch (level) {
      case BoardLevel.pyramid:
        _drawPyramidBoard(canvas, cellSize, linePaint, dotPaint);
        break;
      case BoardLevel.square:
        _drawSquareBoard(canvas, cellSize, linePaint, dotPaint);
        break;
      case BoardLevel.traditional:
        _drawTraditionalBoard(canvas, size.width);
        break;
    }
  }

  void _drawPyramidBoard(Canvas canvas, double cs, Paint lp, Paint dp) {
    Offset p(int c, int r) => Offset(c * cs, r * cs);

    // Apex to row 1
    canvas.drawLine(p(2, 0), p(1, 1), lp);
    canvas.drawLine(p(2, 0), p(3, 1), lp);
    canvas.drawLine(p(1, 1), p(3, 1), lp);

    // Row 1 to row 2 outer slopes
    canvas.drawLine(p(1, 1), p(0, 2), lp);
    canvas.drawLine(p(3, 1), p(4, 2), lp);

    // Row 1 to row 2 inner diagonals
    canvas.drawLine(p(1, 1), p(2, 2), lp);
    canvas.drawLine(p(3, 1), p(2, 2), lp);

    // Verticals for columns 0..4
    canvas.drawLine(p(0, 2), p(0, 4), lp);
    canvas.drawLine(p(1, 1), p(1, 4), lp);
    canvas.drawLine(p(2, 2), p(2, 4), lp);
    canvas.drawLine(p(3, 1), p(3, 4), lp);
    canvas.drawLine(p(4, 2), p(4, 4), lp);

    // Horizontals for rows 2, 3, 4
    for (int row = 2; row <= 4; row++) {
      canvas.drawLine(p(0, row), p(4, row), lp);
    }

    // Dots at all 18 positions
    const points = [
      [2, 0],
      [1, 1], [3, 1],
      [0, 2], [1, 2], [2, 2], [3, 2], [4, 2],
      [0, 3], [1, 3], [2, 3], [3, 3], [4, 3],
      [0, 4], [1, 4], [2, 4], [3, 4], [4, 4],
    ];

    for (final pt in points) {
      canvas.drawCircle(p(pt[0], pt[1]), 5, dp);
    }
  }

  void _drawSquareBoard(Canvas canvas, double cs, Paint lp, Paint dp) {
    Offset p(int c, int r) => Offset(c * cs, r * cs);

    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(p(0, i), p(4, i), lp);
      canvas.drawLine(p(i, 0), p(i, 4), lp);
    }

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        if ((row + col) % 2 == 0) {
          canvas.drawLine(p(col, row), p(col + 1, row + 1), lp);
        } else {
          canvas.drawLine(p(col + 1, row), p(col, row + 1), lp);
        }
      }
    }

    for (int row = 0; row <= 4; row++) {
      for (int col = 0; col <= 4; col++) {
        canvas.drawCircle(p(col, row), 5, dp);
      }
    }
  }

  void _drawTraditionalBoard(Canvas canvas, double boardSize) {
    // Thin, clean black lines for the whole board (matches the reference:
    // 1.6px strokes, no decorative extras).
    final thinLine = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final dot = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    // Clean intersection dots scaled to boardSize
    final dotRadius = boardSize * 0.015;

    // Draw every segment once as a straight line: the 5x5 grid, the
    // checkerboard diagonals + inner diamond, and the four fan extensions
    // (including their flat outer rows).
    for (final (from, to) in traditionalBoardSegments()) {
      canvas.drawLine(
        traditionalPositionOffset(from, boardSize),
        traditionalPositionOffset(to, boardSize),
        thinLine,
      );
    }

    // Small solid circular nodes at every intersection.
    for (final pos in BoardConnections(BoardLevel.traditional).allPositions) {
      canvas.drawCircle(
        traditionalPositionOffset(pos, boardSize),
        dotRadius,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => oldDelegate.level != level;
}
