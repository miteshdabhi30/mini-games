import 'dart:math';

class FlowGenerator {
  final int size;
  final Random _random = Random();

  FlowGenerator(this.size);

  Map<String, dynamic> generate() {
    // 0 = empty
    // 1..N = Flow ID (Color)

    // Attempt to generate a full grid of paths
    // We will use a random walk approach for multiple paths

    final grid = List.generate(size, (_) => List.filled(size, 0));

    // We want to fill as much as possible.
    // Heuristic: Start a few paths, grow them.

    int pathId = 1;
    int attempts = 0;

    int maxAttempts = size * size * 2;
    while (attempts < maxAttempts) {
      // Find empty spot
      Point<int>? start = _findEmpty(grid);
      if (start == null) break; // Full

      grid[start.y][start.x] = pathId;

      Point<int> current = start;
      int length = 1;

      // Walk
      while (true) {
        final neighbors = _getEmptyNeighbors(grid, current);
        if (neighbors.isEmpty) break;

        final next = neighbors[_random.nextInt(neighbors.length)];
        grid[next.y][next.x] = pathId;
        current = next;
        length++;

        // Randomly stop if length is decent?
        if (length > 3 && _random.nextDouble() < 0.1) break;
      }

      // If path is too short (length 1), revert
      if (length < 2) {
        _clearPath(grid, pathId);
        attempts++; // Try again
        continue;
      } else {
        pathId++;
        attempts = 0; // Reset attempts if successful
      }
    }

    // If we have very few paths, maybe retry?
    // Constraint: Minimum paths based on size to ensure difficulty
    // 5x5 -> min 3
    // 6x6 -> min 4
    // 7x7 -> min 5
    // 8x8 -> min 6
    int minPaths = size - 2;
    if (pathId < minPaths)
      return generate(); // Retry recursion to ensure density

    // Now we have a filled grid with active paths.
    // We need to return active ENDPOINTS only.
    // But wait, the bloc needs to know the Solution? Or just the endpoints?
    // The player needs to find A solution. The generator just provides endpoints.
    // So we assume the generated paths are valid endpoints.

    // Return both endpoints and the solution paths
    // We need to reconstruct the paths from the grid history?
    // Actually, we overwrote the grid with pathIDs.
    // We can extract the full paths before clearing them?

    // Better: Helper to extract paths from the filled grid
    final solutionPaths = <int, List<Point<int>>>{};
    for (int id = 1; id < pathId; id++) {
      solutionPaths[id] = _getPointsForId(grid, id);
    }

    // Now create endpoints grid
    final endpoints = List.generate(size, (_) => List.filled(size, 0));

    for (int id = 1; id < pathId; id++) {
      if (solutionPaths.containsKey(id) && solutionPaths[id]!.isNotEmpty) {
        final points = solutionPaths[id]!;
        final start = points.first;
        final end = points.last;
        endpoints[start.y][start.x] = id;
        endpoints[end.y][end.x] = id;
      }
    }

    return {
      'grid': endpoints, // List<List<int>>
      'solution': solutionPaths, // Map<int, List<Point<int>>>
    };
  }

  Point<int>? _findEmpty(List<List<int>> grid) {
    final empty = <Point<int>>[];
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (grid[y][x] == 0) empty.add(Point(x, y));
      }
    }
    if (empty.isEmpty) return null;
    return empty[_random.nextInt(empty.length)];
  }

  List<Point<int>> _getEmptyNeighbors(List<List<int>> grid, Point<int> p) {
    final neighbors = <Point<int>>[];
    final dirs = [Point(0, 1), Point(0, -1), Point(1, 0), Point(-1, 0)];

    for (final d in dirs) {
      final nx = p.x + d.x;
      final ny = p.y + d.y;
      if (nx >= 0 && nx < size && ny >= 0 && ny < size && grid[ny][nx] == 0) {
        neighbors.add(Point(nx, ny));
      }
    }
    return neighbors;
  }

  void _clearPath(List<List<int>> grid, int id) {
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (grid[y][x] == id) grid[y][x] = 0;
      }
    }
  }

  List<Point<int>> _getPointsForId(List<List<int>> grid, int id) {
    final p = <Point<int>>[];
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (grid[y][x] == id) p.add(Point(x, y));
      }
    }
    return p;
  }
}
