package com.tigerhunt.tigerhunt.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.tigerhunt.tigerhunt.model.*
import kotlin.math.*

@Composable
fun GameBoardCanvas(
    gameState: GameState,
    boardTheme: BoardTheme,
    selectedPosition: Position?,
    validMoves: List<Move>,
    hintMove: Move?,
    onNodeClick: (Position) -> Unit,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 0.85f,
        targetValue = 1.15f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_scale"
    )

    val connections = remember(gameState.level) { BoardConnections(gameState.level) }
    val allPositions = remember(gameState.level) { connections.allPositions }

    // Map screen bounds based on board level
    val (minRow, maxRow, minCol, maxCol) = remember(gameState.level) {
        when (gameState.level) {
            BoardLevel.TRADITIONAL -> Tuple4(-2, 6, -2, 6)
            BoardLevel.PYRAMID -> Tuple4(0, 4, 0, 4)
            BoardLevel.SQUARE -> Tuple4(0, 4, 0, 4)
        }
    }

    val totalRows = maxRow - minRow + 1
    val totalCols = maxCol - minCol + 1

    BoxWithConstraints(modifier = modifier.fillMaxWidth().aspectRatio(1f)) {
        val canvasWidth = constraints.maxWidth.toFloat()
        val canvasHeight = constraints.maxHeight.toFloat()
        val boardPadding = 32f
        val usableWidth = canvasWidth - boardPadding * 2
        val usableHeight = canvasHeight - boardPadding * 2

        val cellSpacingX = usableWidth / (totalCols - 1)
        val cellSpacingY = usableHeight / (totalRows - 1)
        val cellSpacing = min(cellSpacingX, cellSpacingY)

        val offsetX = (canvasWidth - cellSpacing * (totalCols - 1)) / 2f
        val offsetY = (canvasHeight - cellSpacing * (totalRows - 1)) / 2f

        fun posToOffset(pos: Position): Offset {
            val colIndex = pos.col - minCol
            val rowIndex = pos.row - minRow
            return Offset(
                x = offsetX + colIndex * cellSpacing,
                y = offsetY + rowIndex * cellSpacing
            )
        }

        fun offsetToPos(touch: Offset): Position? {
            var closestPos: Position? = null
            var minDistance = Float.MAX_VALUE
            val hitRadius = cellSpacing * 0.48f

            for (pos in allPositions) {
                val center = posToOffset(pos)
                val dist = sqrt((touch.x - center.x).pow(2) + (touch.y - center.y).pow(2))
                if (dist <= hitRadius && dist < minDistance) {
                    minDistance = dist
                    closestPos = pos
                }
            }
            return closestPos
        }

        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .testTag("game_board_canvas")
                .pointerInput(gameState, selectedPosition, validMoves) {
                    detectTapGestures { tapOffset ->
                        val clicked = offsetToPos(tapOffset)
                        if (clicked != null) {
                            onNodeClick(clicked)
                        }
                    }
                }
        ) {
            // 1. Draw Board Background and Ornate Frame
            drawRoundRect(
                color = boardTheme.boardBackground,
                topLeft = Offset(8f, 8f),
                size = Size(size.width - 16f, size.height - 16f),
                cornerRadius = CornerRadius(24f, 24f)
            )

            drawRoundRect(
                color = boardTheme.surfaceColor,
                topLeft = Offset(14f, 14f),
                size = Size(size.width - 28f, size.height - 28f),
                cornerRadius = CornerRadius(20f, 20f),
                style = Stroke(width = 3.dp.toPx())
            )

            // Ornate corner accents
            drawCornerAccents(boardTheme.linePrimary, size)

            // 2. Draw Connection Lines
            val drawnLines = mutableSetOf<Pair<Position, Position>>()
            for ((fromPos, neighbors) in connections.connections) {
                val fromOffset = posToOffset(fromPos)
                for (toPos in neighbors) {
                    val pairKey = if (fromPos.hashCode() < toPos.hashCode()) fromPos to toPos else toPos to fromPos
                    if (!drawnLines.contains(pairKey)) {
                        drawnLines.add(pairKey)
                        val toOffset = posToOffset(toPos)
                        drawLine(
                            color = boardTheme.lineSecondary.copy(alpha = 0.85f),
                            start = fromOffset,
                            end = toOffset,
                            strokeWidth = 3.dp.toPx(),
                            cap = StrokeCap.Round
                        )
                    }
                }
            }

            // 3. Draw Nodes (Intersections)
            val nodeRadius = cellSpacing * 0.18f
            for (pos in allPositions) {
                val center = posToOffset(pos)
                val isCollapsed = gameState.isPositionCollapsed(pos)

                if (isCollapsed) {
                    drawCircle(
                        color = Color.DarkGray.copy(alpha = 0.4f),
                        radius = nodeRadius * 0.8f,
                        center = center
                    )
                } else {
                    drawCircle(
                        color = boardTheme.nodeColor.copy(alpha = 0.5f),
                        radius = nodeRadius * 0.6f,
                        center = center
                    )
                    drawCircle(
                        color = boardTheme.linePrimary,
                        radius = nodeRadius * 0.35f,
                        center = center
                    )
                }
            }

            // 4. Draw Valid Destination Move Indicators
            for (move in validMoves) {
                val targetCenter = posToOffset(move.to)
                if (move.isCapture) {
                    // Capture leap target
                    drawCircle(
                        color = Color(0xFFFF5252).copy(alpha = 0.3f),
                        radius = nodeRadius * 1.5f * pulseScale,
                        center = targetCenter
                    )
                    drawCircle(
                        color = Color(0xFFFF1744),
                        radius = nodeRadius * 0.9f,
                        center = targetCenter,
                        style = Stroke(width = 3.dp.toPx())
                    )
                    // Ring over the goat to be captured
                    move.capturedAt?.let { capPos ->
                        val capCenter = posToOffset(capPos)
                        drawCircle(
                            color = Color.Red.copy(alpha = 0.6f),
                            radius = nodeRadius * 1.2f,
                            center = capCenter,
                            style = Stroke(width = 2.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(10f, 10f)))
                        )
                    }
                } else {
                    // Normal move destination
                    drawCircle(
                        color = boardTheme.validMoveColor.copy(alpha = 0.25f),
                        radius = nodeRadius * 1.3f * pulseScale,
                        center = targetCenter
                    )
                    drawCircle(
                        color = boardTheme.validMoveColor,
                        radius = nodeRadius * 0.65f,
                        center = targetCenter
                    )
                }
            }

            // 5. Draw Hint Move Indicator
            hintMove?.let { hint ->
                val hintFrom = if (hint.isPlacement) null else posToOffset(hint.from)
                val hintTo = posToOffset(hint.to)

                if (hintFrom != null) {
                    drawLine(
                        color = Color(0xFF00E5FF),
                        start = hintFrom,
                        end = hintTo,
                        strokeWidth = 4.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(15f, 10f))
                    )
                }
                drawCircle(
                    color = Color(0xFF00E5FF),
                    radius = nodeRadius * 1.4f,
                    center = hintTo,
                    style = Stroke(width = 3.dp.toPx())
                )
            }

            // 6. Draw Selected Piece Glow
            selectedPosition?.let { selPos ->
                val selCenter = posToOffset(selPos)
                drawCircle(
                    color = boardTheme.accentHighlight.copy(alpha = 0.35f),
                    radius = nodeRadius * 2.2f * pulseScale,
                    center = selCenter
                )
                drawCircle(
                    color = boardTheme.accentHighlight,
                    radius = nodeRadius * 1.8f,
                    center = selCenter,
                    style = Stroke(width = 3.dp.toPx())
                )
            }

            // 7. Draw Pieces on Board
            val pieceRadius = cellSpacing * 0.36f
            for (piece in gameState.pieces) {
                if (piece.isCaptured) continue
                val center = posToOffset(piece.position)

                if (piece.type == PieceType.TIGER) {
                    drawTigerPiece(center, pieceRadius, boardTheme)
                } else {
                    val isShielded = gameState.isGoatShielded(piece.position)
                    val isStunned = gameState.isGoatStunned(piece.position)
                    drawGoatPiece(center, pieceRadius, boardTheme, isShielded, isStunned)
                }
            }
        }
    }
}

private fun DrawScope.drawTigerPiece(center: Offset, radius: Float, theme: BoardTheme) {
    // Shadow
    drawCircle(
        color = Color.Black.copy(alpha = 0.5f),
        radius = radius + 2.dp.toPx(),
        center = center.copy(y = center.y + 3.dp.toPx())
    )

    // Outer Gilded Token Ring
    drawCircle(
        brush = Brush.radialGradient(
            colors = listOf(Color(0xFFFFD54F), Color(0xFFB78103)),
            center = center,
            radius = radius
        ),
        radius = radius,
        center = center
    )

    // Inner Amber Body
    drawCircle(
        brush = Brush.linearGradient(
            colors = listOf(theme.tigerColor, Color(0xFFB71C1C)),
            start = Offset(center.x - radius, center.y - radius),
            end = Offset(center.x + radius, center.y + radius)
        ),
        radius = radius * 0.85f,
        center = center
    )

    // Tiger Face Silhouette / Stripes
    val earRadius = radius * 0.28f
    drawCircle(
        color = Color(0xFF3E1200),
        radius = earRadius,
        center = Offset(center.x - radius * 0.55f, center.y - radius * 0.55f)
    )
    drawCircle(
        color = Color(0xFF3E1200),
        radius = earRadius,
        center = Offset(center.x + radius * 0.55f, center.y - radius * 0.55f)
    )

    // Fierce Eyes (Glowing Gold)
    drawCircle(
        color = Color(0xFFFFD700),
        radius = radius * 0.12f,
        center = Offset(center.x - radius * 0.3f, center.y - radius * 0.15f)
    )
    drawCircle(
        color = Color(0xFFFFD700),
        radius = radius * 0.12f,
        center = Offset(center.x + radius * 0.3f, center.y - radius * 0.15f)
    )

    // Snout
    drawCircle(
        color = Color(0xFFFFCC80),
        radius = radius * 0.28f,
        center = Offset(center.x, center.y + radius * 0.25f)
    )
    drawCircle(
        color = Color(0xFF210A00),
        radius = radius * 0.1f,
        center = Offset(center.x, center.y + radius * 0.15f)
    )
}

private fun DrawScope.drawGoatPiece(
    center: Offset,
    radius: Float,
    theme: BoardTheme,
    isShielded: Boolean,
    isStunned: Boolean
) {
    // Shadow
    drawCircle(
        color = Color.Black.copy(alpha = 0.4f),
        radius = radius + 2.dp.toPx(),
        center = center.copy(y = center.y + 2.dp.toPx())
    )

    // Shield aura if active
    if (isShielded) {
        drawCircle(
            color = Color(0xFF00E5FF).copy(alpha = 0.4f),
            radius = radius * 1.35f,
            center = center
        )
    }

    // Outer Rim
    drawCircle(
        color = if (isStunned) Color(0xFF90CAF9) else Color(0xFFBDBDBD),
        radius = radius * 0.9f,
        center = center
    )

    // Ivory Body
    drawCircle(
        brush = Brush.radialGradient(
            colors = listOf(Color.White, theme.goatColor, Color(0xFFD7CCC8)),
            center = center,
            radius = radius * 0.8f
        ),
        radius = radius * 0.78f,
        center = center
    )

    // Goat Horns (Curved lines)
    val hornColor = if (isStunned) Color(0xFF1565C0) else Color(0xFF5D4037)
    val path = Path().apply {
        moveTo(center.x - radius * 0.2f, center.y - radius * 0.1f)
        cubicTo(
            center.x - radius * 0.5f, center.y - radius * 0.6f,
            center.x - radius * 0.6f, center.y - radius * 0.3f,
            center.x - radius * 0.4f, center.y - radius * 0.05f
        )
        moveTo(center.x + radius * 0.2f, center.y - radius * 0.1f)
        cubicTo(
            center.x + radius * 0.5f, center.y - radius * 0.6f,
            center.x + radius * 0.6f, center.y - radius * 0.3f,
            center.x + radius * 0.4f, center.y - radius * 0.05f
        )
    }
    drawPath(path, color = hornColor, style = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round))

    // Goat Eyes
    drawCircle(
        color = Color(0xFF2E1C0C),
        radius = radius * 0.09f,
        center = Offset(center.x - radius * 0.22f, center.y + radius * 0.05f)
    )
    drawCircle(
        color = Color(0xFF2E1C0C),
        radius = radius * 0.09f,
        center = Offset(center.x + radius * 0.22f, center.y + radius * 0.05f)
    )
}

private fun DrawScope.drawCornerAccents(color: Color, size: Size) {
    val len = 20.dp.toPx()
    val margin = 20.dp.toPx()
    val stroke = 2.dp.toPx()

    // Top-Left
    drawLine(color, Offset(margin, margin), Offset(margin + len, margin), stroke)
    drawLine(color, Offset(margin, margin), Offset(margin, margin + len), stroke)

    // Top-Right
    drawLine(color, Offset(size.width - margin, margin), Offset(size.width - margin - len, margin), stroke)
    drawLine(color, Offset(size.width - margin, margin), Offset(size.width - margin, margin + len), stroke)

    // Bottom-Left
    drawLine(color, Offset(margin, size.height - margin), Offset(margin + len, size.height - margin), stroke)
    drawLine(color, Offset(margin, size.height - margin), Offset(margin, size.height - margin - len), stroke)

    // Bottom-Right
    drawLine(color, Offset(size.width - margin, size.height - margin), Offset(size.width - margin - len, size.height - margin), stroke)
    drawLine(color, Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - len), stroke)
}

private data class Tuple4<A, B, C, D>(val a: A, val b: B, val c: C, val d: D)
