import 'dart:math';
import 'package:flame/components.dart';
import '../models/bubble_color.dart';

class GridSlot {
  final int row;
  final int col;

  const GridSlot(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridSlot &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';
}

class BubbleGrid {
  final double gameWidth;
  final double topPadding;
  final int maxCols;

  late final double bubbleRadius;
  late final double bubbleDiameter;
  late final double rowHeight;

  // 2D grid storing BubbleType or null
  final List<List<BubbleType?>> _cells = [];

  BubbleGrid({
    required this.gameWidth,
    this.topPadding = 50.0,
    this.maxCols = 8,
  }) {
    // Width fits maxCols bubbles plus half a bubble offset for odd rows
    bubbleDiameter = gameWidth / (maxCols + 0.5);
    bubbleRadius = bubbleDiameter / 2;
    // Hexagonal geometry vertical pitch: R * sqrt(3)
    rowHeight = bubbleRadius * sqrt(3);
  }

  int get rowCount => _cells.length;

  int getColsForRow(int row) => (row % 2 == 0) ? maxCols : maxCols - 1;

  BubbleType? get(int row, int col) {
    if (row < 0 || row >= _cells.length) return null;
    if (col < 0 || col >= getColsForRow(row)) return null;
    return _cells[row][col];
  }

  void set(int row, int col, BubbleType? type) {
    _ensureRows(row + 1);
    if (col >= 0 && col < getColsForRow(row)) {
      _cells[row][col] = type;
    }
  }

  void _ensureRows(int count) {
    while (_cells.length < count) {
      final r = _cells.length;
      final cols = getColsForRow(r);
      _cells.add(List<BubbleType?>.filled(cols, null));
    }
  }

  /// Initialize grid from level data
  void loadLevelGrid(List<List<BubbleType?>> initialGrid) {
    _cells.clear();
    for (int r = 0; r < initialGrid.length; r++) {
      final cols = getColsForRow(r);
      final rowList = List<BubbleType?>.filled(cols, null);
      for (int c = 0; c < min(cols, initialGrid[r].length); c++) {
        rowList[c] = initialGrid[r][c];
      }
      _cells.add(rowList);
    }
  }

  /// Center coordinates of a slot
  Vector2 getSlotCenter(int row, int col) {
    final bool isOdd = (row % 2 == 1);
    final double x = isOdd
        ? bubbleDiameter + col * bubbleDiameter
        : bubbleRadius + col * bubbleDiameter;
    final double y = topPadding + bubbleRadius + row * rowHeight;
    return Vector2(x, y);
  }

  /// Return all 6 valid hexagonal neighbors of (row, col)
  List<GridSlot> getNeighbors(int row, int col) {
    final neighbors = <GridSlot>[];
    final bool isOdd = (row % 2 == 1);

    // Left and Right
    _addIfValid(neighbors, row, col - 1);
    _addIfValid(neighbors, row, col + 1);

    // Top-left and Top-right
    if (isOdd) {
      _addIfValid(neighbors, row - 1, col);
      _addIfValid(neighbors, row - 1, col + 1);
    } else {
      _addIfValid(neighbors, row - 1, col - 1);
      _addIfValid(neighbors, row - 1, col);
    }

    // Bottom-left and Bottom-right
    if (isOdd) {
      _addIfValid(neighbors, row + 1, col);
      _addIfValid(neighbors, row + 1, col + 1);
    } else {
      _addIfValid(neighbors, row + 1, col - 1);
      _addIfValid(neighbors, row + 1, col);
    }

    return neighbors;
  }

  void _addIfValid(List<GridSlot> list, int row, int col) {
    if (row < 0) return;
    final cols = getColsForRow(row);
    if (col >= 0 && col < cols) {
      list.add(GridSlot(row, col));
    }
  }

  /// Find nearest empty slot to position [pos] that connects to ceiling or an existing bubble
  GridSlot findBestSnapSlot(Vector2 pos) {
    // Expand grid rows by 2 if needed to allow snapping below lowest bubble
    _ensureRows(_cells.length + 2);

    GridSlot? bestSlot;
    double minDistance = double.infinity;

    for (int r = 0; r < _cells.length; r++) {
      final cols = getColsForRow(r);
      for (int c = 0; c < cols; c++) {
        if (_cells[r][c] != null) continue; // slot must be empty

        // Must either be on the top row (r == 0) or neighbor at least one occupied bubble
        bool hasAnchor = (r == 0);
        if (!hasAnchor) {
          final neighbors = getNeighbors(r, c);
          for (final n in neighbors) {
            if (get(n.row, n.col) != null) {
              hasAnchor = true;
              break;
            }
          }
        }

        if (hasAnchor) {
          final center = getSlotCenter(r, c);
          final dist = center.distanceTo(pos);
          if (dist < minDistance) {
            minDistance = dist;
            bestSlot = GridSlot(r, c);
          }
        }
      }
    }

    return bestSlot ?? const GridSlot(0, 0);
  }

  /// Check collision between a projectile circle and any occupied bubble in the grid
  bool checkCollision(Vector2 pos, double radius) {
    // Check ceiling collision
    if (pos.y - radius <= topPadding) {
      return true;
    }

    // Check collision with all occupied slots
    final hitDistance = (radius + bubbleRadius) * 0.95;
    for (int r = 0; r < _cells.length; r++) {
      final cols = getColsForRow(r);
      for (int c = 0; c < cols; c++) {
        if (_cells[r][c] != null) {
          final center = getSlotCenter(r, c);
          if (center.distanceTo(pos) <= hitDistance) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// BFS search for matching color cluster starting at (startRow, startCol)
  List<GridSlot> findMatchingCluster(int startRow, int startCol) {
    final targetType = get(startRow, startCol);
    if (targetType == null) return [];

    // Special bomb bubble: detonates surrounding 2-ring radius!
    if (targetType == BubbleType.bomb) {
      final bombCluster = <GridSlot>{GridSlot(startRow, startCol)};
      final neighbors = getNeighbors(startRow, startCol);
      for (final n in neighbors) {
        if (get(n.row, n.col) != null) bombCluster.add(n);
        for (final nn in getNeighbors(n.row, n.col)) {
          if (get(nn.row, nn.col) != null) bombCluster.add(nn);
        }
      }
      return bombCluster.toList();
    }

    final cluster = <GridSlot>[];
    final visited = <GridSlot>{};
    final queue = <GridSlot>[GridSlot(startRow, startCol)];
    visited.add(GridSlot(startRow, startCol));

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      cluster.add(current);

      for (final neighbor in getNeighbors(current.row, current.col)) {
        if (visited.contains(neighbor)) continue;

        final neighborType = get(neighbor.row, neighbor.col);
        if (neighborType == null) continue;

        // Match exact color, or match if either is Rainbow
        if (neighborType == targetType ||
            targetType == BubbleType.rainbow ||
            neighborType == BubbleType.rainbow) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    return cluster;
  }

  /// Find all floating/orphan bubbles not anchored to the ceiling
  List<GridSlot> findFloatingBubbles() {
    if (_cells.isEmpty) return [];

    final connectedToCeiling = <GridSlot>{};
    final queue = <GridSlot>[];

    // Find all bubbles anchored at ceiling row 0
    final topCols = getColsForRow(0);
    for (int c = 0; c < topCols; c++) {
      if (_cells[0][c] != null) {
        final slot = GridSlot(0, c);
        connectedToCeiling.add(slot);
        queue.add(slot);
      }
    }

    // Traverse all reachable bubbles from ceiling
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final neighbor in getNeighbors(current.row, current.col)) {
        if (!connectedToCeiling.contains(neighbor) &&
            get(neighbor.row, neighbor.col) != null) {
          connectedToCeiling.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    // Any bubble in the grid that was not reached is an orphan!
    final orphans = <GridSlot>[];
    for (int r = 0; r < _cells.length; r++) {
      final cols = getColsForRow(r);
      for (int c = 0; c < cols; c++) {
        if (_cells[r][c] != null) {
          final slot = GridSlot(r, c);
          if (!connectedToCeiling.contains(slot)) {
            orphans.add(slot);
          }
        }
      }
    }

    return orphans;
  }

  /// Remove bubble at slot
  void remove(int row, int col) {
    if (row >= 0 && row < _cells.length && col >= 0 && col < getColsForRow(row)) {
      _cells[row][col] = null;
    }
  }

  /// Total count of bubbles currently in grid
  int get activeBubbleCount {
    int count = 0;
    for (final row in _cells) {
      for (final cell in row) {
        if (cell != null) count++;
      }
    }
    return count;
  }

  /// Set of unique active bubble types present in the grid
  Set<BubbleType> get activeColors {
    final colors = <BubbleType>{};
    for (final row in _cells) {
      for (final cell in row) {
        if (cell != null &&
            cell != BubbleType.bomb &&
            cell != BubbleType.rainbow) {
          colors.add(cell);
        }
      }
    }
    return colors;
  }

  /// Highest Y position among active bubbles (lowest on screen)
  double get lowestBubbleY {
    double maxY = topPadding;
    for (int r = _cells.length - 1; r >= 0; r--) {
      final cols = getColsForRow(r);
      for (int c = 0; c < cols; c++) {
        if (_cells[r][c] != null) {
          return getSlotCenter(r, c).y + bubbleRadius;
        }
      }
    }
    return maxY;
  }

  /// Clean empty trailing rows
  void trimEmptyRows() {
    while (_cells.isNotEmpty) {
      final lastRow = _cells.last;
      if (lastRow.every((cell) => cell == null)) {
        _cells.removeLast();
      } else {
        break;
      }
    }
  }
}
