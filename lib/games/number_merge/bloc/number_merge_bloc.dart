import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/number_merge/bloc/number_merge_event.dart';
import 'package:green_object/games/number_merge/bloc/number_merge_state.dart';
import 'package:green_object/utils/high_score_store.dart';

class NumberMergeBloc extends Bloc<NumberMergeEvent, NumberMergeState> {
  static const int rows = 7;
  static const int cols = 5;
  final Random _random = Random();

  NumberMergeBloc() : super(const NumberMergeState()) {
    on<NumberMergeStarted>(_onStarted);
    on<NumberMergeColumnTapped>(_onColumnTapped);
    on<NumberMergeRestarted>(_onRestarted);
    on<NumberMergeRevived>(_onRevived);
  }

  void _onRevived(NumberMergeRevived event, Emitter<NumberMergeState> emit) {
    if (state.status != NumberMergeStatus.gameOver || state.reviveUsed) return;

    // Revive Logic: Clear top 3 rows of every column to give space
    final newGrid = [for (final col in state.grid) List<int>.from(col)];

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < 3; r++) {
        // Clear top 3 rows (0, 1, 2)
        if (r < rows) {
          newGrid[c][r] = 0;
        }
      }
    }

    emit(
      state.copyWith(
        status: NumberMergeStatus.playing,
        grid: newGrid,
        reviveUsed: true,
      ),
    );
  }

  void _onStarted(NumberMergeStarted event, Emitter<NumberMergeState> emit) {
    _startGame(emit);
  }

  void _onRestarted(
    NumberMergeRestarted event,
    Emitter<NumberMergeState> emit,
  ) {
    _startGame(emit);
  }

  void _startGame(Emitter<NumberMergeState> emit) {
    final highScore = HighScoreStore.getHighScore('numberMerge_highScore');
    final grid = List.generate(cols, (_) => List.filled(rows, 0));
    final nextNum = _generateNextNumber();

    emit(
      state.copyWith(
        status: NumberMergeStatus.playing,
        score: 0,
        highScore: highScore,
        grid: grid,
        nextNumber: nextNum,
      ),
    );
  }

  void _onColumnTapped(
    NumberMergeColumnTapped event,
    Emitter<NumberMergeState> emit,
  ) {
    if (state.status != NumberMergeStatus.playing) return;

    final col = event.columnIndex;
    if (col < 0 || col >= cols) return;

    List<List<int>> newGrid = [
      for (final c in state.grid) List<int>.from(c),
    ]; // Deep copy
    final column = newGrid[col];

    // Find lowest empty spot
    int dropRow = -1;
    for (int r = rows - 1; r >= 0; r--) {
      if (column[r] == 0) {
        dropRow = r;
        break;
      }
    }

    if (dropRow == -1) {
      // Column is full -> Game Over
      _gameOver(emit, state.score);
      return;
    }

    // Place the number
    column[dropRow] = state.nextNumber;

    // Check for merges recursively
    int scoreAdded = 0;
    _checkMerge(newGrid, col, dropRow, (points) {
      scoreAdded += points;
    });

    // Generate next number based on max number on board
    final nextNum = _generateNextNumber(grid: newGrid);

    // Update state
    final newScore = state.score + scoreAdded;
    emit(state.copyWith(grid: newGrid, score: newScore, nextNumber: nextNum));

    // Check game over (if column full after placement/merge? usually immediate check on tap if full)
    // Here we placed it successfully.
    // However, if the grid is completely full and no merges possible...
    // Actually, "Column Full" is the main fail state in these games.
    // We already checked before placement.
    // If placement fills the column to top, that is effectively "risk".
    // Usually game over is when you try to place and can't, OR when a block sticks out.
    // Our logic: If can't place -> Game Over. So it's fine.
  }

  void _checkMerge(
    List<List<int>> grid,
    int col,
    int row,
    Function(int) onMerge,
  ) {
    if (row >= rows) return; // Out of bounds
    if (grid[col][row] == 0) return; // Empty

    // Check below
    if (row + 1 < rows) {
      final current = grid[col][row];
      final below = grid[col][row + 1];

      if (current == below) {
        // Merge!
        final mergedValue = current * 2;
        grid[col][row + 1] = mergedValue;
        grid[col][row] = 0; // Remove current

        // Drop logic: If there were blocks above 'row', they should fall?
        // In "Drop the Number", blocks strictly stack.
        // If we merge into the one below, the one above (if any) becomes the new bottom-most empty spot?
        // Actually, usually things fall.
        // Simplified Logic:
        // 1. Merge into row+1.
        // 2. Clear row.
        // 3. Shift everything above 'row' down by 1.
        _shiftColumnDown(grid[col], row);

        onMerge(mergedValue);

        // Recurse on the new position (row + 1)
        _checkMerge(grid, col, row + 1, onMerge);

        // Also checks neighbor? Usually merge is only vertical or connection based.
        // "Drop the number" usually merges adjacent identical numbers (horizontal/vertical).
        // Requirement said "Like 2048 but falling style".
        // Usually primarily vertical merge, sometimes horizontal side-merge.
        // Let's stick to Vertical Merge first for simplicity and "Stacking" feel.
        // Wait, "2048 falling" often allows horizontal merge too.
        // Let's add Horizontal Merge check *after* vertical land.
        _checkHorizontalMerge(grid, col, row + 1, onMerge);
      }
    }
    // If not merging down, maybe we can merge sideways?
    // Let's implement horizontal merge: if neighbor columns have same number at same row/adjacent?
    // "Drop the Number" (popular mobile game): Blocks merge with adjacent same numbers.
    // If I drop a 2 on a 2 -> 4.
    // If that 4 is next to another 4 -> 8.
    // Let's stick to vertical first explicitly stated "merges same numbers by tapping" (placing on top).
    // "Screen fills -> game over".
    // I'll stick to vertical stack merging.
  }

  void _checkHorizontalMerge(
    List<List<int>> grid,
    int col,
    int row,
    Function(int) onMerge,
  ) {
    // If we implemented horizontal, it would be complex (merging distinct columns).
    // Let's implement strictly vertical stacking 2048 for now.
  }

  void _shiftColumnDown(List<int> column, int emptyRowIndex) {
    // Shift everything from 0 to emptyRowIndex-1 DOWN by 1.
    for (int r = emptyRowIndex; r > 0; r--) {
      column[r] = column[r - 1];
    }
    column[0] = 0; // Top becomes empty
  }

  int _generateNextNumber({List<List<int>>? grid}) {
    // Generate 2, 4, 8, 16, 32 based on progress
    // Max number on grid?
    int maxVal = 2;
    if (grid != null) {
      for (var c in grid) {
        for (var val in c) {
          if (val > maxVal) maxVal = val;
        }
      }
    }

    // Range of possible spawns: 2 up to maxVal / 2 (or /4)
    // To keep it playable.
    // weighted random?
    // Let's spawn 2, 4, 8 ... up to 64
    // standard probability.

    // Simplified:
    // If maxVal is high, allow higher spawns.

    // Skew towards lower numbers
    final r = _random.nextDouble();
    int val = 2;
    if (r < 0.5)
      val = 2;
    else if (r < 0.8)
      val = 4;
    else if (r < 0.95)
      val = 8;
    else if (r < 0.99)
      val = 16;
    else
      val = 32;

    // Constrain by max available
    while (val > maxVal && val > 2) {
      val ~/= 2;
    }
    return val;
  }

  Future<void> _gameOver(Emitter<NumberMergeState> emit, int score) async {
    await HighScoreStore.setHighScore('numberMerge_highScore', score);
    emit(state.copyWith(status: NumberMergeStatus.gameOver));
  }
}
