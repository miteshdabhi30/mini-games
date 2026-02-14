import 'dart:math';

class FlowGenerator {
  final int size;
  final int minFlows;
  final Random _random = Random();

  FlowGenerator(this.size, {this.minFlows = 0});

  Map<String, dynamic> generate() {
    // 0 = empty
    // 1..N = Flow ID (Color)

    final grid = List.generate(size, (_) => List.filled(size, 0));
    final paths = <int, List<Point<int>>>{};

    int pathId = 1;
    int attempts = 0;
    int maxAttempts = size * size * 10; // Increased attempts for better filling

    while (attempts < maxAttempts) {
      // Find empty spot for start
      Point<int>? start = _findEmpty(grid);
      if (start == null) break; // Full

      // Start a new path
      List<Point<int>> currentPath = [start];
      grid[start.y][start.x] = pathId;

      Point<int> current = start;

      // Walk
      while (true) {
        final neighbors = _getEmptyNeighbors(grid, current);
        if (neighbors.isEmpty) {
          break;
        }

        final next = neighbors[_random.nextInt(neighbors.length)];
        grid[next.y][next.x] = pathId;
        currentPath.add(next);
        current = next;

        // Randomly stop if length is decent to allow other paths
        // Heuristic: proportional to size
        if (currentPath.length > size && _random.nextDouble() < 0.1) break;
      }

      // If path is too short, discard and retry
      if (currentPath.length < 3) {
        // Clear this failed path
        for (final p in currentPath) {
          grid[p.y][p.x] = 0;
        }
        attempts++;
        continue;
      } else {
        // Accepted path
        paths[pathId] = currentPath;
        pathId++;
        attempts = 0; // Reset attempts since we made progress
      }
    }

    // Optimization: Fill remaining isolated gaps if possible
    // (Simple implementation: just leave them empty for now,
    // but ideally we'd extend existing paths to fill them)

    // Ensure we have enough paths for a valid level
    int targetMin = minFlows > 0 ? minFlows : (size / 2).ceil() + 1;
    if (paths.length < targetMin) {
      // Retry if generation was poor
      return generate();
    }

    // Create Endpoints Grid
    // Only the Start and End of each path are "Fixed Endpoints"
    final endpoints = List.generate(size, (_) => List.filled(size, 0));
    final solution = <int, List<Point<int>>>{};

    paths.forEach((id, path) {
      final start = path.first;
      final end = path.last;

      endpoints[start.y][start.x] = id;
      endpoints[end.y][end.x] = id;

      solution[id] = path;
    });

    return {
      'grid': endpoints, // List<List<int>> containing ONLY endpoints
      'solution': solution, // Map<int, List<Point<int>>> full paths
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
}
