package com.tigerhunt.tigerhunt.model

/**
 * Encapsulates the graph adjacency connections and jump geometry for all board types.
 */
class BoardConnections(val level: BoardLevel) {
    val connections: Map<Position, List<Position>> = buildConnections()
    val jumps: Map<Position, Map<Position, Position>> = buildJumps()

    val allPositions: List<Position> get() = connections.keys.toList()

    fun getNeighbors(pos: Position): List<Position> = connections[pos] ?: emptyList()

    fun areConnected(a: Position, b: Position): Boolean = connections[a]?.contains(b) ?: false

    fun isValidPosition(pos: Position): Boolean = connections.containsKey(pos)

    fun getDirection(from: Position, to: Position): Position? {
        if (!areConnected(from, to)) return null
        return Position(to.row - from.row, to.col - from.col)
    }

    fun getJumpDestination(from: Position, over: Position): Position? {
        val mappedDest = jumps[from]?.get(over)
        if (mappedDest != null) return mappedDest

        val direction = getDirection(from, over) ?: return null
        val dest = Position(over.row + direction.row, over.col + direction.col)
        if (!isValidPosition(dest)) return null
        if (!areConnected(over, dest)) return null
        return dest
    }

    private fun addCollinearLine(
        jumpMap: MutableMap<Position, MutableMap<Position, Position>>,
        line: List<Position>
    ) {
        for (i in 0 until line.size - 2) {
            val a = line[i]
            val b = line[i + 1]
            val c = line[i + 2]
            jumpMap.getOrPut(a) { mutableMapOf() }[b] = c
            jumpMap.getOrPut(c) { mutableMapOf() }[b] = a
        }
    }

    private fun buildConnections(): Map<Position, List<Position>> {
        val conn = mutableMapOf<Position, MutableList<Position>>()
        fun link(a: Position, b: Position) {
            conn.getOrPut(a) { mutableListOf() }.add(b)
            conn.getOrPut(b) { mutableListOf() }.add(a)
        }

        when (level) {
            BoardLevel.PYRAMID -> {
                // Top apex (0,2) to (1,1) and (1,3)
                link(Position(0, 2), Position(1, 1))
                link(Position(0, 2), Position(1, 3))
                link(Position(1, 1), Position(1, 3))

                // Row 1 to Row 2
                link(Position(1, 1), Position(2, 0))
                link(Position(1, 3), Position(2, 4))
                link(Position(1, 1), Position(2, 1))
                link(Position(1, 3), Position(2, 3))
                link(Position(1, 1), Position(2, 2))
                link(Position(1, 3), Position(2, 2))

                // Rows 2, 3, 4 (5x3 grid)
                for (row in 2..4) {
                    for (col in 0..3) {
                        link(Position(row, col), Position(row, col + 1))
                    }
                }
                for (col in 0..4) {
                    link(Position(2, col), Position(3, col))
                    link(Position(3, col), Position(4, col))
                }
            }
            BoardLevel.SQUARE -> {
                for (row in 0 until 5) {
                    for (col in 0 until 5) {
                        val pos = Position(row, col)
                        if (row > 0) link(pos, Position(row - 1, col))
                        if (col > 0) link(pos, Position(row, col - 1))
                        val hasDiagonal = (row + col) % 2 == 0
                        if (hasDiagonal) {
                            if (row > 0 && col > 0) link(pos, Position(row - 1, col - 1))
                            if (row > 0 && col < 4) link(pos, Position(row - 1, col + 1))
                        }
                    }
                }
            }
            BoardLevel.TRADITIONAL -> {
                // Main 5x5 grid positions
                for (row in 0 until 5) {
                    for (col in 0 until 5) {
                        val pos = Position(row, col)
                        if (row > 0) link(pos, Position(row - 1, col))
                        if (col > 0) link(pos, Position(row, col - 1))
                    }
                }
                // Two main diagonals
                link(Position(0, 0), Position(1, 1))
                link(Position(1, 1), Position(2, 2))
                link(Position(2, 2), Position(3, 3))
                link(Position(3, 3), Position(4, 4))

                link(Position(0, 4), Position(1, 3))
                link(Position(1, 3), Position(2, 2))
                link(Position(2, 2), Position(3, 1))
                link(Position(3, 1), Position(4, 0))

                // Inner diamond
                link(Position(0, 2), Position(1, 1))
                link(Position(0, 2), Position(1, 3))
                link(Position(1, 1), Position(2, 0))
                link(Position(1, 3), Position(2, 4))
                link(Position(2, 0), Position(3, 1))
                link(Position(2, 4), Position(3, 3))
                link(Position(3, 1), Position(4, 2))
                link(Position(3, 3), Position(4, 2))

                // Fan Extensions
                // Top Fan
                link(Position(0, 2), Position(-1, 1))
                link(Position(0, 2), Position(-1, 2))
                link(Position(0, 2), Position(-1, 3))
                for (c in 1..3) link(Position(-1, c), Position(-2, c))
                link(Position(-1, 1), Position(-1, 2))
                link(Position(-1, 2), Position(-1, 3))
                link(Position(-2, 1), Position(-2, 2))
                link(Position(-2, 2), Position(-2, 3))

                // Bottom Fan
                link(Position(4, 2), Position(5, 1))
                link(Position(4, 2), Position(5, 2))
                link(Position(4, 2), Position(5, 3))
                for (c in 1..3) link(Position(5, c), Position(6, c))
                link(Position(5, 1), Position(5, 2))
                link(Position(5, 2), Position(5, 3))
                link(Position(6, 1), Position(6, 2))
                link(Position(6, 2), Position(6, 3))

                // Left Fan
                link(Position(2, 0), Position(1, -1))
                link(Position(2, 0), Position(2, -1))
                link(Position(2, 0), Position(3, -1))
                for (r in 1..3) link(Position(r, -1), Position(r, -2))
                link(Position(1, -1), Position(2, -1))
                link(Position(2, -1), Position(3, -1))
                link(Position(1, -2), Position(2, -2))
                link(Position(2, -2), Position(3, -2))

                // Right Fan
                link(Position(2, 4), Position(1, 5))
                link(Position(2, 4), Position(2, 5))
                link(Position(2, 4), Position(3, 5))
                for (r in 1..3) link(Position(r, 5), Position(r, 6))
                link(Position(1, 5), Position(2, 5))
                link(Position(2, 5), Position(3, 5))
                link(Position(1, 6), Position(2, 6))
                link(Position(2, 6), Position(3, 6))
            }
        }
        return conn
    }

    private fun buildJumps(): Map<Position, Map<Position, Position>> {
        val jumpMap = mutableMapOf<Position, MutableMap<Position, Position>>()
        fun addLine(line: List<Position>) = addCollinearLine(jumpMap, line)

        when (level) {
            BoardLevel.PYRAMID -> {
                addLine(listOf(Position(0, 2), Position(1, 1), Position(2, 0), Position(3, 0), Position(4, 0)))
                addLine(listOf(Position(0, 2), Position(1, 3), Position(2, 4), Position(3, 4), Position(4, 4)))
                addLine(listOf(Position(2, 0), Position(3, 0), Position(4, 0)))
                addLine(listOf(Position(1, 1), Position(2, 1), Position(3, 1), Position(4, 1)))
                addLine(listOf(Position(2, 2), Position(3, 2), Position(4, 2)))
                addLine(listOf(Position(1, 3), Position(2, 3), Position(3, 3), Position(4, 3)))
                addLine(listOf(Position(2, 4), Position(3, 4), Position(4, 4)))

                addLine(listOf(Position(2, 0), Position(2, 1), Position(2, 2), Position(2, 3), Position(2, 4)))
                addLine(listOf(Position(3, 0), Position(3, 1), Position(3, 2), Position(3, 3), Position(3, 4)))
                addLine(listOf(Position(4, 0), Position(4, 1), Position(4, 2), Position(4, 3), Position(4, 4)))
            }
            BoardLevel.SQUARE -> {
                for (r in 0 until 5) addLine((0 until 5).map { c -> Position(r, c) })
                for (c in 0 until 5) addLine((0 until 5).map { r -> Position(r, c) })

                addLine(listOf(Position(0, 2), Position(1, 3), Position(2, 4)))
                addLine(listOf(Position(0, 1), Position(1, 2), Position(2, 3), Position(3, 4)))
                addLine(listOf(Position(0, 0), Position(1, 1), Position(2, 2), Position(3, 3), Position(4, 4)))
                addLine(listOf(Position(1, 0), Position(2, 1), Position(3, 2), Position(4, 3)))
                addLine(listOf(Position(2, 0), Position(3, 1), Position(4, 2)))

                addLine(listOf(Position(0, 2), Position(1, 1), Position(2, 0)))
                addLine(listOf(Position(0, 3), Position(1, 2), Position(2, 1), Position(3, 0)))
                addLine(listOf(Position(0, 4), Position(1, 3), Position(2, 2), Position(3, 1), Position(4, 0)))
                addLine(listOf(Position(1, 4), Position(2, 3), Position(3, 2), Position(4, 1)))
                addLine(listOf(Position(2, 4), Position(3, 3), Position(4, 2)))
            }
            BoardLevel.TRADITIONAL -> {
                for (r in 0 until 5) addLine((0 until 5).map { c -> Position(r, c) })
                for (c in 0 until 5) addLine((0 until 5).map { r -> Position(r, c) })

                addLine(listOf(Position(0, 0), Position(1, 1), Position(2, 2), Position(3, 3), Position(4, 4)))
                addLine(listOf(Position(0, 4), Position(1, 3), Position(2, 2), Position(3, 1), Position(4, 0)))

                addLine(listOf(Position(0, 2), Position(1, 1), Position(2, 0)))
                addLine(listOf(Position(0, 2), Position(1, 3), Position(2, 4)))
                addLine(listOf(Position(2, 0), Position(3, 1), Position(4, 2)))
                addLine(listOf(Position(2, 4), Position(3, 3), Position(4, 2)))

                // Top fan lines
                addLine(listOf(Position(1, 3), Position(0, 2), Position(-1, 1), Position(-2, 1)))
                addLine(listOf(Position(1, 2), Position(0, 2), Position(-1, 2), Position(-2, 2)))
                addLine(listOf(Position(1, 1), Position(0, 2), Position(-1, 3), Position(-2, 3)))
                addLine(listOf(Position(-1, 1), Position(-1, 2), Position(-1, 3)))
                addLine(listOf(Position(-2, 1), Position(-2, 2), Position(-2, 3)))

                // Bottom fan lines
                addLine(listOf(Position(3, 3), Position(4, 2), Position(5, 1), Position(6, 1)))
                addLine(listOf(Position(3, 2), Position(4, 2), Position(5, 2), Position(6, 2)))
                addLine(listOf(Position(3, 1), Position(4, 2), Position(5, 3), Position(6, 3)))
                addLine(listOf(Position(5, 1), Position(5, 2), Position(5, 3)))
                addLine(listOf(Position(6, 1), Position(6, 2), Position(6, 3)))

                // Left fan lines
                addLine(listOf(Position(3, 1), Position(2, 0), Position(1, -1), Position(1, -2)))
                addLine(listOf(Position(2, 1), Position(2, 0), Position(2, -1), Position(2, -2)))
                addLine(listOf(Position(1, 1), Position(2, 0), Position(3, -1), Position(3, -2)))
                addLine(listOf(Position(1, -1), Position(2, -1), Position(3, -1)))
                addLine(listOf(Position(1, -2), Position(2, -2), Position(3, -2)))

                // Right fan lines
                addLine(listOf(Position(3, 3), Position(2, 4), Position(1, 5), Position(1, 6)))
                addLine(listOf(Position(2, 3), Position(2, 4), Position(2, 5), Position(2, 6)))
                addLine(listOf(Position(1, 3), Position(2, 4), Position(3, 5), Position(3, 6)))
                addLine(listOf(Position(1, 5), Position(2, 5), Position(3, 5)))
                addLine(listOf(Position(1, 6), Position(2, 6), Position(3, 6)))
            }
        }
        return jumpMap
    }
}
