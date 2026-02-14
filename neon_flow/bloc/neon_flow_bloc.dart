import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/neon_flow/bloc/neon_flow_event.dart';
import 'package:green_object/games/neon_flow/bloc/neon_flow_state.dart';
import 'package:green_object/games/neon_flow/utils/flow_generator.dart';
import 'package:green_object/utils/high_score_store.dart';

class NeonFlowBloc extends Bloc<NeonFlowEvent, NeonFlowState> {
  NeonFlowBloc() : super(const NeonFlowState()) {
    on<NeonFlowLevelStarted>(_onStarted);
    on<NeonFlowNextLevel>(_onNextLevel);
    on<NeonFlowRestartLevel>(_onRestartLevel);
    on<NeonFlowDragStarted>(_onDragStart);
    on<NeonFlowDragUpdated>(_onDragUpdate);
    on<NeonFlowDragEnded>(_onDragEnd);
    on<NeonFlowRevived>(_onRevived); // Keep as "Hint" basically
    on<NeonFlowHint>(_onHint);
  }

  void _onStarted(NeonFlowLevelStarted event, Emitter<NeonFlowState> emit) {
    _startLevel(emit, 1);
  }

  void _onNextLevel(NeonFlowNextLevel event, Emitter<NeonFlowState> emit) {
    _startLevel(emit, state.level + 1);
  }

  void _onRestartLevel(
    NeonFlowRestartLevel event,
    Emitter<NeonFlowState> emit,
  ) {
    // Restart CURRENT level.
    // We need to regenerate the grid or just clear paths?
    // Usually "Restart" means clear paths but keep same grid?
    // Or plain new grid?
    // Let's keep same grid for frustration-free retry, or just clear paths.
    // But if we want a fresh start, we can regenerate.
    // The user said "Game Over" -> "Restart".
    // Let's just clear paths to let them try the SAME puzzle again.
    emit(
      state.copyWith(
        status: NeonFlowStatus.playing,
        paths: {},
        currentDrawingId: null,
      ),
    );
  }

  void _startLevel(Emitter<NeonFlowState> emit, int level) {
    int size = 5;
    int minFlows = 3;

    // Difficulty Scaling Logic

    // Levels 1-3: Easy (5x5, ~3 flows)
    if (level <= 3) {
      size = 5;
      minFlows = 3;
    }
    // Levels 4-6: Medium (5x5, ~4-5 flows)
    else if (level <= 6) {
      size = 5;
      minFlows = 4;
    }
    // Levels 7-10: Hard (6x6, ~4-5 flows)
    else if (level <= 10) {
      size = 6;
      minFlows = 4;
    }
    // Levels 11-15: Expert (6x6, ~5-6 flows)
    else if (level <= 15) {
      size = 6;
      minFlows = 5;
    }
    // Levels 16-20: Master (7x7, ~5-6 flows)
    else if (level <= 20) {
      size = 7;
      minFlows = 5;
    }
    // Levels 21+: Grandmaster (8x8, max complexity)
    else {
      size = 8;
      minFlows = 6;
    }

    final generator = FlowGenerator(size, minFlows: minFlows);
    Map<String, dynamic> genResult = {
      'grid': <List<int>>[],
      'solution': <int, List<Point<int>>>{},
    };

    // Retry logic for generator
    for (int i = 0; i < 5; i++) {
      genResult = generator.generate();
      final g = genResult['grid'] as List<List<int>>;
      if (g.isNotEmpty && g[0].isNotEmpty) break;
    }

    final grid = genResult['grid'] as List<List<int>>;
    final solution = genResult['solution'] as Map<int, List<Point<int>>>;

    // Fallback if still empty (should not happen with retries)
    if (grid.isEmpty) {
      // Could emit error, but let's just emit empty state to avoid crash, UI handles loading
    }

    final highScore = HighScoreStore.getHighScore('neonFlow_highScore');

    emit(
      NeonFlowState(
        status: NeonFlowStatus.playing,
        size: size,
        grid: grid,
        paths: {},
        solution: solution,
        currentDrawingId: null,
        level: level,
        score: state.score,
        highScore: highScore,
        reviveCount: level == 1 ? 0 : state.reviveCount,
      ),
    );
  }

  bool _isPathCompleted(
    int id,
    Map<int, List<Point<int>>> paths,
    List<List<int>> grid,
  ) {
    if (!paths.containsKey(id)) return false;
    final p = paths[id]!;
    if (p.length < 2) return false;
    final start = p.first;
    final end = p.last;

    // Check if start and end are endpoints for this ID
    int endpointsHit = 0;
    if (grid[start.y][start.x] == id) endpointsHit++;
    if (grid[end.y][end.x] == id) endpointsHit++;

    return endpointsHit == 2;
  }

  void _onDragStart(NeonFlowDragStarted event, Emitter<NeonFlowState> emit) {
    if (state.status != NeonFlowStatus.playing) return;

    final r = event.row;
    final c = event.col;

    // Check bounds
    if (r < 0 || r >= state.size || c < 0 || c >= state.size) return;

    // Check if we hit an endpoint
    int id = state.grid[r][c];

    // OR Check if we hit an existing path
    if (id == 0) {
      state.paths.forEach((key, points) {
        if (points.contains(Point(c, r))) {
          id = key;
        }
      });
    }

    if (id != 0) {
      // LOCKED PATH CHECK: If this path is already completed, do not allow modifying it.
      if (_isPathCompleted(id, state.paths, state.grid)) {
        return;
      }

      // Start drawing for this ID
      final newPaths = Map<int, List<Point<int>>>.from(state.paths);

      if (!newPaths.containsKey(id)) {
        newPaths[id] = [Point(c, r)];
      } else {
        if (state.grid[r][c] == id) {
          // If touching endpoint of an incomplete path,
          // We usually clear it to restart, OR if we touch the END of the current path we continue.
          // But to be simple/classic: Touching endpoint clears path.
          newPaths[id] = [Point(c, r)];
        } else {
          // Touching middle of path, truncate
          final points = newPaths[id]!;
          final index = points.indexOf(Point(c, r));
          if (index != -1) {
            newPaths[id] = points.sublist(0, index + 1);
          }
        }
      }

      emit(state.copyWith(paths: newPaths, currentDrawingId: id));
    }
  }

  void _onDragUpdate(NeonFlowDragUpdated event, Emitter<NeonFlowState> emit) {
    if (state.status != NeonFlowStatus.playing ||
        state.currentDrawingId == null)
      return;

    final id = state.currentDrawingId!;

    // NEW LOCK CHECK: If path just became complete during this drag (e.g. user hit endpoint), stop adding.
    // Actually, we check this *before* adding the next point? No, we need to check if *current* path is complete.
    if (_isPathCompleted(id, state.paths, state.grid)) {
      return;
    }

    final r = event.row;
    final c = event.col;

    if (r < 0 || r >= state.size || c < 0 || c >= state.size) return;

    final currentPath = List<Point<int>>.from(state.paths[id]!);
    final lastPoint = currentPath.last;

    if (lastPoint.x == c && lastPoint.y == r) return; // Same point

    // Check adjacency (manhattan distance == 1)
    if ((lastPoint.x - c).abs() + (lastPoint.y - r).abs() != 1)
      return; // Not adjacent (jumped)

    // Handle Backtracking
    if (currentPath.length > 1 &&
        currentPath[currentPath.length - 2] == Point(c, r)) {
      currentPath.removeLast();
      final newPaths = Map<int, List<Point<int>>>.from(state.paths);
      newPaths[id] = currentPath;
      emit(state.copyWith(paths: newPaths));
      return;
    }

    // Collision Checks
    // 1. Cannot cross self
    if (currentPath.contains(Point(c, r))) return;

    // 2. Cannot cross other Endpoints (unless it's the OWN endpoint)
    final gridVal = state.grid[r][c];
    if (gridVal != 0 && gridVal != id) return; // Hit another color's endpoint

    // 3. Cannot cross other Paths
    final newPaths = Map<int, List<Point<int>>>.from(state.paths);
    bool collisionImpossible = false;

    newPaths.forEach((otherId, points) {
      if (otherId != id) {
        if (points.contains(Point(c, r))) {
          // LOCKED PATH CHECK: If *other* path is completed, we CANNOT cut it. We stop.
          if (_isPathCompleted(otherId, state.paths, state.grid)) {
            collisionImpossible = true;
          } else {
            // Cut this path
            final index = points.indexOf(Point(c, r));
            newPaths[otherId] = points.sublist(0, index);
          }
        }
      }
    });

    if (collisionImpossible) return;

    // Add point
    currentPath.add(Point(c, r));
    newPaths[id] = currentPath;

    // LOCKING: If we just hit the endpoint, validly, the path is now "Complete" and should lock.
    // The next update will catch this with `_isPathCompleted` check at top.

    emit(state.copyWith(paths: newPaths));

    // Check Level Complete?
    // Usually on DragEnd, but maybe instant?
    // Flow Free is instant.
    if (_checkLevelComplete(state.grid, newPaths, state.size)) {
      final newScore = state.score + (state.level * 100);
      final highScore = max(state.highScore, newScore);
      if (highScore > state.highScore) {
        HighScoreStore.setHighScore('neonFlow_highScore', highScore);
      }

      emit(
        state.copyWith(
          status: NeonFlowStatus.levelCompleted,
          score: newScore,
          highScore: highScore,
          paths: newPaths, // final state
        ),
      );

      // Auto advance after delay? handled in UI
    }
  }

  void _onDragEnd(NeonFlowDragEnded event, Emitter<NeonFlowState> emit) {
    emit(state.copyWith(currentDrawingId: null));

    // Check GAME OVER condition
    if (state.status == NeonFlowStatus.playing) {
      if (_checkGameOver(state.grid, state.paths, state.size)) {
        emit(state.copyWith(status: NeonFlowStatus.gameOver));
      }
    }
  }

  bool _isReachable(
    Point<int> start,
    Point<int> target,
    int myId,
    List<List<int>> grid,
    Map<int, List<Point<int>>> paths,
    int size,
  ) {
    final queue = <Point<int>>[start];
    final visited = <Point<int>>{start};

    // Build a set of blocked points for O(1) lookup
    final blocked = <Point<int>>{};

    // Add other colors' endpoints
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final val = grid[r][c];
        if (val != 0 && val != myId) {
          blocked.add(Point(c, r));
        }
      }
    }

    // Add locked paths
    paths.forEach((id, points) {
      if (id != myId && _isPathCompleted(id, paths, grid)) {
        blocked.addAll(points);
      }
    });

    final dirs = [Point(0, 1), Point(0, -1), Point(1, 0), Point(-1, 0)];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == target) return true;

      for (final d in dirs) {
        final next = Point(current.x + d.x, current.y + d.y);

        if (next.x >= 0 && next.x < size && next.y >= 0 && next.y < size) {
          if (!visited.contains(next) && !blocked.contains(next)) {
            visited.add(next);
            queue.add(next);
          }
        }
      }
    }

    return false;
  }

  void _onHint(NeonFlowHint event, Emitter<NeonFlowState> emit) {
    // Find a path that is not yet completed correctly
    // We check against the solution
    int? hintId;

    // Iterate through solution keys
    for (final id in state.solution.keys) {
      // Is this path already drawn perfectly?
      // Check if state.paths[id] matches state.solution[id]
      // Or simpler: check if current path connects endpoints.
      // If not connected, or wrong, we can hint it.

      bool isSolved = false;
      if (state.paths.containsKey(id)) {
        final p = state.paths[id]!;
        if (p.length > 1) {
          final start = p.first;
          final end = p.last;
          if (state.grid[start.y][start.x] == id &&
              state.grid[end.y][end.x] == id) {
            isSolved = true;
          }
        }
      }

      if (!isSolved) {
        hintId = id;
        break;
      }
    }

    if (hintId != null) {
      // reveal solution for this ID
      final newPaths = Map<int, List<Point<int>>>.from(state.paths);
      newPaths[hintId] = state.solution[hintId]!;

      // Also clear any other paths that intersect with this hint (since hint is definitive)
      // The generator ensures solution paths are disjoint.
      // So if user drew a wrong path crossing this hint, we must cut it.
      final hintPath = newPaths[hintId]!;

      newPaths.forEach((otherId, points) {
        if (otherId != hintId) {
          // Check intersection
          // Use a Set for fast lookup? Or naive iteration (paths are short)
          for (final hp in hintPath) {
            if (points.contains(hp)) {
              // Cut other path
              final index = points.indexOf(hp);
              newPaths[otherId] = points.sublist(0, index);
              break; // Cut once is enough
            }
          }
        }
      });

      emit(state.copyWith(paths: newPaths));

      // Check completion after hint
      if (_checkLevelComplete(state.grid, newPaths, state.size)) {
        // ... logic similar to drag update
        final newScore = state.score + (state.level * 100); // Bonus?
        final highScore = max(state.highScore, newScore);
        if (highScore > state.highScore) {
          HighScoreStore.setHighScore('neonFlow_highScore', highScore);
        }

        emit(
          state.copyWith(
            status: NeonFlowStatus.levelCompleted,
            score: newScore,
            highScore: highScore,
            paths: newPaths,
          ),
        );
      }
    }
  }

  void _onRevived(NeonFlowRevived event, Emitter<NeonFlowState> emit) {
    if (state.reviveCount >= 2) return; // Max revives reached

    // Revive Action: Cascading Fix.
    // 1. Identify a blocked path (or any incomplete path if strictly "stuck").
    // 2. recursive-check: If we solve X, does it overlap Y? If so, solve Y too.

    int? startId;
    final ids = <int>{};
    for (var row in state.grid) {
      for (var val in row) {
        if (val != 0) ids.add(val);
      }
    }

    // Find a blocked I (start point for cascade)
    // Only search among INCOMPLETE paths.
    for (final id in ids) {
      if (_isPathCompleted(id, state.paths, state.grid)) continue;

      List<Point<int>> endpoints = [];
      for (int r = 0; r < state.size; r++) {
        for (int c = 0; c < state.size; c++) {
          if (state.grid[r][c] == id) endpoints.add(Point(c, r));
        }
      }

      if (endpoints.length == 2) {
        if (!_isReachable(
          endpoints[0],
          endpoints[1],
          id,
          state.grid,
          state.paths,
          state.size,
        )) {
          startId = id;
          break;
        }
      }
    }

    // If nothing strictly "blocked" found (maybe just logic error?), pick ANY incomplete one.
    if (startId == null) {
      for (final id in ids) {
        if (!_isPathCompleted(id, state.paths, state.grid)) {
          startId = id;
          break;
        }
      }
    }

    if (startId != null) {
      final solutionPath = state.solution[startId]!;
      final solutionSet = solutionPath.toSet();

      final newPaths = Map<int, List<Point<int>>>.from(state.paths);

      // 1. Solve the blocked path
      newPaths[startId] = solutionPath;

      // 2. Clear (Delete) any EXISTING paths that overlap with this solution
      // This "makes a clear way" without solving the whole level for the user.
      final idsToRemove = <int>{};

      newPaths.forEach((otherId, otherPath) {
        if (otherId == startId) return;

        for (final p in otherPath) {
          if (solutionSet.contains(p)) {
            idsToRemove.add(otherId);
            break; // Overlap found, remove entire path
          }
        }
      });

      for (final id in idsToRemove) {
        newPaths.remove(id);
      }

      emit(
        state.copyWith(
          status: NeonFlowStatus.playing, // Resume playing
          paths: newPaths,
          reviveCount: state.reviveCount + 1,
        ),
      );

      // Check if this accidentally finished the level (unlikely if we removed things, but possible if last move)
      if (_checkLevelComplete(state.grid, newPaths, state.size)) {
        final newScore = state.score + (state.level * 100);
        final highScore = max(state.highScore, newScore);
        if (highScore > state.highScore) {
          HighScoreStore.setHighScore('neonFlow_highScore', highScore);
        }

        emit(
          state.copyWith(
            status: NeonFlowStatus.levelCompleted,
            score: newScore,
            highScore: highScore,
            paths: newPaths,
          ),
        );
      }
    }
  }

  bool _checkGameOver(
    List<List<int>> grid,
    Map<int, List<Point<int>>> paths,
    int size,
  ) {
    // Revised Game Over Logic:
    // Game Over ONLY if ALL incomplete paths are blocked.
    // i.e., "If there exists at least one incomplete path that is REACHABLE, then NOT Game Over."

    final ids = <int>{};
    for (var row in grid) {
      for (var val in row) {
        if (val != 0) ids.add(val);
      }
    }

    bool hasPlayableMove = false;
    bool hasIncompletePaths = false;

    for (final id in ids) {
      if (_isPathCompleted(id, paths, grid)) continue; // Already done

      hasIncompletePaths = true;

      // Check reachability
      List<Point<int>> endpoints = [];
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (grid[r][c] == id) endpoints.add(Point(c, r));
        }
      }

      if (endpoints.length != 2) continue;

      final start = endpoints[0];
      final target = endpoints[1];

      if (_isReachable(start, target, id, grid, paths, size)) {
        hasPlayableMove = true;
        break; // Found one playable move, so NOT Game Over
      }
    }

    // Game Over if we have work to do, but NO playable moves.
    if (hasIncompletePaths && !hasPlayableMove) {
      return true;
    }
    return false;
  }

  bool _checkLevelComplete(
    List<List<int>> grid,
    Map<int, List<Point<int>>> paths,
    int size,
  ) {
    // 1. All colors must have a valid path connecting start and end
    final ids = <int>{};
    for (var row in grid) {
      for (var val in row) {
        if (val != 0) ids.add(val);
      }
    }

    for (final id in ids) {
      if (!paths.containsKey(id)) return false;
      final p = paths[id]!;
      if (p.length < 2) return false;

      final start = p.first;
      final end = p.last;

      if (grid[start.y][start.x] != id) return false;
      if (grid[end.y][end.x] != id) return false;
    }

    return true;
  }
}
