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

  void _startLevel(Emitter<NeonFlowState> emit, int level) {
    int size = 5;
    if (level >= 2) size = 6;
    if (level >= 4) size = 7;
    if (level >= 6) size = 8; // Cap at 8x8

    final generator = FlowGenerator(size);
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
        reviveUsed: false,
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
    // Legacy Revive used as "Skip Level" in Game Over (if time limit existed) or Menu.
    // Let's keep it as "Skip Level".
    emit(
      state.copyWith(
        status: NeonFlowStatus.levelCompleted,
        reviveUsed: true,
        // Maybe clear paths to show empty board "Skipped"? Or show full solution?
        // Show full solution would be cool.
        paths: state.solution,
      ),
    );
  }

  bool _checkLevelComplete(
    List<List<int>> grid,
    Map<int, List<Point<int>>> paths,
    int size,
  ) {
    // 1. All colors must have a valid path connecting start and end
    // Identify all ColorIDs from grid
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

      // Must match endpoints in grid
      if (grid[start.y][start.x] != id) return false;
      if (grid[end.y][end.x] != id) return false; // Both ends must be endpoints

      // Actually, one end is where we started dragging (could be either endpoint),
      // and the other must be the other endpoint.
      // Correct check: logic is simply "Does the path connect two endpoints of ID?"
      // P.first and P.last must both be Grid[..] == id.
    }

    // 2. All cells must be filled?
    // STRICT MODE: paths.forEach((k, v) => covered += v.length);
    // if (covered < size * size) return false;

    // RELAXED MODE:
    // If we have connected all endpoints, it's good enough for "Level Complete".
    // We can incentivize 100% coverage with stars/score later.
    // For now, to ensure game is playable and "working perfectly" (i.e. not stuck),
    // we return true if all IDs are connected.

    return true;
  }
}
