import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../models/game_state.dart';
import '../models/board_connections.dart';

/// Maps a Traditional-board position to its pixel offset, matching the
/// reference layout exactly. The 5x5 grid occupies the central half of the
/// canvas (0.25..0.75) and the four fan-shaped extensions reach toward the
/// edges: each fan has a flat outer row of 3 nodes and an inner row of 3
/// nodes, with the side nodes slanting inward so the outer rows are narrower
/// than the inner rows.
Offset traditionalPositionOffset(Position pos, double boardSize) {
  // Central 5x5 grid (normalized 0.25..0.75).
  if (pos.row >= 0 && pos.row <= 4 && pos.col >= 0 && pos.col <= 4) {
    return Offset(
      (0.25 + pos.col * 0.125) * boardSize,
      (0.25 + pos.row * 0.125) * boardSize,
    );
  }

  // Top fan: outer row at y=0.035 (x: 0.39, 0.50, 0.61), inner row at
  // y=0.135 (x: 0.43, 0.50, 0.57); hub is grid (0,2) at (0.50, 0.25).
  if (pos.row == -1 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.43 + (pos.col - 1) * 0.07) * boardSize, 0.135 * boardSize);
  }
  if (pos.row == -2 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.39 + (pos.col - 1) * 0.11) * boardSize, 0.035 * boardSize);
  }

  // Bottom fan (mirror of the top fan).
  if (pos.row == 5 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.43 + (pos.col - 1) * 0.07) * boardSize, 0.865 * boardSize);
  }
  if (pos.row == 6 && pos.col >= 1 && pos.col <= 3) {
    return Offset((0.39 + (pos.col - 1) * 0.11) * boardSize, 0.965 * boardSize);
  }

  // Left fan (mirror of the top fan, rotated).
  if (pos.col == -1 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.135 * boardSize, (0.43 + (pos.row - 1) * 0.07) * boardSize);
  }
  if (pos.col == -2 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.035 * boardSize, (0.39 + (pos.row - 1) * 0.11) * boardSize);
  }

  // Right fan (mirror of the left fan).
  if (pos.col == 5 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.865 * boardSize, (0.43 + (pos.row - 1) * 0.07) * boardSize);
  }
  if (pos.col == 6 && pos.row >= 1 && pos.row <= 3) {
    return Offset(0.965 * boardSize, (0.39 + (pos.row - 1) * 0.11) * boardSize);
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

            return Padding(
              padding: EdgeInsets.all(margin),
              child: CustomPaint(
                size: Size(boardSize, boardSize),
                painter: _BoardPainter(level: level),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (showHints)
                      ...validMoves.map((move) => _buildMoveIndicator(move, boardSize)),
                    ...gameState.pieces
                        .where((p) => !p.isCaptured)
                        .map((piece) => _buildPiece(piece, boardSize)),
                    ..._buildTouchTargets(boardSize),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Offset _positionToOffset(Position pos, double boardSize) {
    if (level == BoardLevel.traditional) {
      return traditionalPositionOffset(pos, boardSize);
    }
    final cellSize = boardSize / 4;
    return Offset(pos.col * cellSize, pos.row * cellSize);
  }

  Widget _buildMoveIndicator(Move move, double boardSize) {
    final offset = _positionToOffset(move.to, boardSize);
    final indicatorSize = (boardSize / (level == BoardLevel.traditional ? 16 : 14)).clamp(16.0, 28.0);
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
    final pieceSize = boardSize / (level == BoardLevel.traditional ? 8.5 : 7.0);

    return AnimatedPositioned(
      key: ValueKey(piece.id),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: offset.dx - pieceSize / 2,
      top: offset.dy - pieceSize / 2,
      child: GestureDetector(
        onTap: () => onPositionTap(piece.position),
        child: Container(
          width: pieceSize,
          height: pieceSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTiger ? const Color(0xFFE86A17) : Colors.white,
            border: Border.all(
              color: isSelected
                  ? Colors.green
                  : (isTiger ? const Color(0xFFB5510D) : const Color(0xFF333333)),
              width: isSelected ? 3.5 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isTiger ? '🐯' : '🐐',
              style: TextStyle(fontSize: pieceSize * 0.55),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTouchTargets(double boardSize) {
    final connections = BoardConnections(level);
    final touchSize = (boardSize / (level == BoardLevel.traditional ? 7.5 : 6.0)).clamp(36.0, 60.0);
    return connections.allPositions.map((pos) {
      final offset = _positionToOffset(pos, boardSize);
      if (gameState.getPieceAt(pos) != null) return const SizedBox.shrink();

      return Positioned(
        left: offset.dx - touchSize / 2,
        top: offset.dy - touchSize / 2,
        child: GestureDetector(
          onTap: () => onPositionTap(pos),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: touchSize,
            height: touchSize,
            color: Colors.transparent,
          ),
        ),
      );
    }).toList();
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
    // Reference uses a 7px node on a ~320px canvas; scale to keep that ratio.
    final dotRadius = boardSize * 0.022;

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
