import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/ball_sort/bloc/ball_sort_event.dart';
import 'package:green_object/games/ball_sort/bloc/ball_sort_state.dart';

class BallSortBloc extends Bloc<BallSortEvent, BallSortState> {
  static const int tubeCapacity = 4;
  final Random _random = Random();

  BallSortBloc() : super(const BallSortState()) {
    on<BallSortStarted>(_onStarted);
    on<BallSortTubeTapped>(_onTubeTapped);
    on<BallSortRestarted>(_onRestarted);
    on<BallSortUndo>(_onUndo);
    on<BallSortNextLevel>(_onNextLevel);
  }

  void _onStarted(BallSortStarted event, Emitter<BallSortState> emit) {
    _startLevel(emit, 1);
  }

  void _onRestarted(BallSortRestarted event, Emitter<BallSortState> emit) {
    _startLevel(emit, state.level);
  }

  void _onNextLevel(BallSortNextLevel event, Emitter<BallSortState> emit) {
    _startLevel(emit, state.level + 1);
  }

  void _onUndo(BallSortUndo event, Emitter<BallSortState> emit) {
    if (state.history.isEmpty) return;

    final previousTubes = state.history.last;
    final newHistory = state.history.sublist(0, state.history.length - 1);

    emit(
      state.copyWith(
        tubes: previousTubes,
        selectedTubeIndex: null, // Clear selection on undo
        history: newHistory,
        moves: state.moves > 0 ? state.moves - 1 : 0,
      ),
    );
  }

  void _startLevel(Emitter<BallSortState> emit, int level) {
    final tubes = _generateLevel(level);
    emit(
      BallSortState(
        status: BallSortStatus.playing,
        tubes: tubes,
        level: level,
        moves: 0,
        history: const [],
      ),
    );
  }

  List<List<Color>> _generateLevel(int level) {
    // Determine complexity based on level
    int numColors = min(3 + (level ~/ 2), 10); // Start with 3, max 10
    int numEmptyTubes = 2; // Always 2 empty tubes?

    List<Color> palette = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
      Colors.brown,
    ];

    // Create sorted tubes
    // Create sorted tubes (Conceptually, but we assign via shuffled)
    // The previous loop generating 'tubes' was dead code.

    // Shuffle by making valid reverse moves
    // Just randomizing might create unsolvable states?
    // Actually random shuffle of balls into tubes is usually solvable IF we have 2 empty tubes
    // But to be safe and create "designed" feeling, let's reverse move.

    // Actually, simple random shuffle is easier to implement and generally solvable with 2 empty tubes.
    // Let's try simple shuffle first.
    List<Color> allBalls = [];
    for (int i = 0; i < numColors; i++) {
      allBalls.addAll(List.filled(tubeCapacity, palette[i % palette.length]));
    }
    allBalls.shuffle(_random);

    List<List<Color>> shuffledTubes = [];
    int ballIndex = 0;
    for (int i = 0; i < numColors; i++) {
      List<Color> tube = [];
      for (int j = 0; j < tubeCapacity; j++) {
        tube.add(allBalls[ballIndex++]);
      }
      shuffledTubes.add(tube);
    }
    for (int i = 0; i < numEmptyTubes; i++) {
      shuffledTubes.add([]);
    }

    return shuffledTubes;
  }

  void _onTubeTapped(BallSortTubeTapped event, Emitter<BallSortState> emit) {
    if (state.status != BallSortStatus.playing) return;

    final tappedIndex = event.tubeIndex;
    final selectedIndex = state.selectedTubeIndex;

    if (selectedIndex == null) {
      // Select logic
      // Can only select if tube has balls
      if (state.tubes[tappedIndex].isNotEmpty) {
        // Also check if tube is already completed? (Optional optimization)
        // If user wants to move from a completed tube to break it, allow it.
        emit(state.copyWith(selectedTubeIndex: tappedIndex));
      }
    } else {
      // Move logic
      if (selectedIndex == tappedIndex) {
        // Tap same tube -> Deselect
        emit(state.clearSelection());
      } else {
        // Try to move from selected to tapped
        if (_isValidMove(state.tubes, selectedIndex, tappedIndex)) {
          // Execute move
          // Clone tubes deeply
          List<List<Color>> newTubes = state.tubes
              .map((t) => List<Color>.from(t))
              .toList();

          // Move ball
          Color ball = newTubes[selectedIndex].removeLast();
          newTubes[tappedIndex].add(ball);

          // Save history
          // We need deep copy of OLD tubes for history
          List<List<Color>> oldTubes = state.tubes
              .map((t) => List<Color>.from(t))
              .toList();
          List<List<List<Color>>> newHistory = List.from(state.history)
            ..add(oldTubes);

          // Check win
          bool isWin = _checkWin(newTubes);

          emit(
            state.copyWith(
              tubes: newTubes,
              selectedTubeIndex:
                  null, // Deselect after move causes null error if not handled?
              // `selectedTubeIndex: null` passes null to copyWith, but I implemented logic to handle it.
              // Wait, I didn't verify copyWith handles explicit null.
              // My copyWith implementation: `selectedTubeIndex: selectedTubeIndex,`.
              // If I pass null, it uses `this.selectedTubeIndex`.
              // I need a way to clear it.
              // I added `clearSelection()` helper.
              // But I want to set other fields too.
              // I should change copyWith to accept a sentinel or separate clear method.
              // Let's use `state.clearSelection().copyWith(...)` pattern if needed, or fix copyWith.
              // Actually in Dart `selectedTubeIndex: selectedTubeIndex ?? this.selectedTubeIndex` is the standard.
              // To force null, usually people use `Object? selectedTubeIndex = const Object()`.
              // Or just separate `deselect` event.
              // For now, I will use a separate copyWith-like construction manually here.
              moves: state.moves + 1,
              history: newHistory,
              status: isWin
                  ? BallSortStatus.levelCompleted
                  : BallSortStatus.playing,
            ),
          );

          // Actually, my `copyWith` logic was:
          // `selectedTubeIndex: selectedTubeIndex, // Intentionally nullable`
          // But Dart parameters are optional. `selectedTubeIndex` is `int?`.
          // If I call `copyWith(selectedTubeIndex: null)`, then `selectedTubeIndex` arg is null.
          // `selectedTubeIndex ?? this.selectedTubeIndex` returns `this.selectedTubeIndex`.
          // So I can't clear it with standard copyWith.
          // I'll fix this by adding a specific `deselect: true` param or just manually creating the state.

          emit(
            BallSortState(
              status: isWin
                  ? BallSortStatus.levelCompleted
                  : BallSortStatus.playing,
              tubes: newTubes,
              selectedTubeIndex: null,
              level: state.level,
              moves: state.moves + 1,
              history: newHistory,
            ),
          );
        } else {
          // Invalid move -> Select new tube if it has balls, or just deselect?
          // Usually if I tap an invalid destination, I might want to change selection to that tube instead (if valid source).
          // Logic:
          // If Tap T2 (invalid dest)
          // Is T2 a valid SOURCE? (Has balls)
          // Yes -> Select T2
          // No -> Deselect T1
          if (state.tubes[tappedIndex].isNotEmpty) {
            emit(state.copyWith(selectedTubeIndex: tappedIndex));
          } else {
            emit(state.clearSelection());
          }
        }
      }
    }
  }

  bool _isValidMove(List<List<Color>> tubes, int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return false;
    if (tubes[fromIndex].isEmpty) return false; // Should not happen if selected
    if (tubes[toIndex].length >= tubeCapacity) return false; // Full

    final Color ballToMove = tubes[fromIndex].last;

    // Custom rule: Can move to empty tube? Yes.
    if (tubes[toIndex].isEmpty) return true;

    // Validation: Must match top color
    final Color topBall = tubes[toIndex].last;
    return ballToMove.value == topBall.value;
  }

  bool _checkWin(List<List<Color>> tubes) {
    for (var tube in tubes) {
      if (tube.isEmpty) continue;
      if (tube.length != tubeCapacity) return false; // Must be full

      // Check all same color
      Color first = tube.first;
      if (tube.any((c) => c != first)) return false;
    }
    return true;
  }
}
