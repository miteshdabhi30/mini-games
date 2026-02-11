import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'package:uuid/uuid.dart';
import 'tower_stack_event.dart';
import 'tower_stack_state.dart';

class TowerStackBloc extends Bloc<TowerStackEvent, TowerStackState> {
  // Config
  static const double baseWidth = 200.0;
  static const double initialSpeed = 150.0;

  double _screenWidth = 400.0; // Pass via setScreenSize

  TowerStackBloc() : super(const TowerStackState()) {
    on<TowerStackStarted>(_onStarted);
    on<TowerStackTicked>(_onTicked);
    on<TowerStackTapped>(_onTapped);
    on<TowerStackRestarted>(_onRestarted);
    on<TowerStackRevived>(_onRevived);
  }

  void setScreenSize(double w, double h) {
    _screenWidth = w;
  }

  Future<void> _onStarted(
    TowerStackStarted event,
    Emitter<TowerStackState> emit,
  ) async {
    final highScore = HighScoreStore.getHighScore('towerStack_highScore');

    // Initial Base Block
    final baseBlock = StackBlock(
      id: const Uuid().v4(),
      x: (_screenWidth - baseWidth) / 2, // Centered
      width: baseWidth,
      y: 0, // Level 0
      color: Colors.cyan,
    );

    emit(
      state.copyWith(
        status: TowerStackStatus.playing,
        highScore: highScore,
        stack: [baseBlock],
        currentBlockWidth: baseWidth,
        currentBlockX: 0,
        score: event.bonusScore,
        speed: initialSpeed,
        reviveUsed: false,
      ),
    );
  }

  void _onRestarted(
    TowerStackRestarted event,
    Emitter<TowerStackState> emit,
  ) async {
    // Re-run start logic
    add(TowerStackStarted(bonusScore: event.bonusScore));
  }

  void _onRevived(TowerStackRevived event, Emitter<TowerStackState> emit) {
    if (state.status != TowerStackStatus.gameOver || state.reviveUsed) return;

    final List<StackBlock> nextStack = List.from(state.stack);
    final int removable = nextStack.length - 1; // keep base block
    final int removeCount = removable >= 3 ? 3 : removable;
    if (removeCount > 0) {
      nextStack.removeRange(nextStack.length - removeCount, nextStack.length);
    }

    final StackBlock top = nextStack.last;
    final int nextScore = nextStack.length - 1;

    emit(
      state.copyWith(
        status: TowerStackStatus.playing,
        stack: nextStack,
        score: nextScore,
        currentBlockWidth: top.width,
        currentBlockX: 0,
        movementDirection: 1,
        reviveUsed: true,
      ),
    );
  }

  void _onTapped(TowerStackTapped event, Emitter<TowerStackState> emit) {
    if (state.status != TowerStackStatus.playing) return;

    // Place block logic
    final currentStack = List<StackBlock>.from(state.stack);
    final topBlock = currentStack.last;

    final currentX = state.currentBlockX;
    final currentW = state.currentBlockWidth;

    // Check overlap with topBlock
    // Overlap range: [max(currentX, topBlock.x), min(currentX+W, topBlock.x+topBlock.width)]

    double overlapStart = max(currentX, topBlock.x);
    double overlapEnd = min(currentX + currentW, topBlock.x + topBlock.width);
    double overlapWidth = overlapEnd - overlapStart;

    if (overlapWidth <= 0) {
      // Missed completely!
      final int nextHighScore = state.score > state.highScore
          ? state.score
          : state.highScore;
      if (nextHighScore != state.highScore) {
        _saveHighScore(nextHighScore);
      }
      emit(
        state.copyWith(
          status: TowerStackStatus.gameOver,
          highScore: nextHighScore,
          reviveUsed: state.reviveUsed,
        ),
      );
    } else {
      // Placed successfully (sliced)
      // New block X is overlapStart
      // New block Width is overlapWidth

      final nextColor = Colors.primaries[state.score % Colors.primaries.length];

      final newBlock = StackBlock(
        id: const Uuid().v4(),
        x: overlapStart,
        width: overlapWidth,
        y: (state.score + 1).toDouble(), // Level up
        color: nextColor,
      );

      currentStack.add(newBlock);

      // Speed up
      double nextSpeed = state.speed + 10.0;

      emit(
        state.copyWith(
          stack: currentStack,
          score: state.score + 1,
          currentBlockWidth: overlapWidth, // Next moving block inherits width
          currentBlockX: 0, // Reset position for next move (or random side)
          speed: nextSpeed,
        ),
      );
    }
  }

  void _onTicked(TowerStackTicked event, Emitter<TowerStackState> emit) {
    if (state.status != TowerStackStatus.playing) return;

    // Move current block
    double newX =
        state.currentBlockX +
        (state.speed * state.movementDirection * event.deltaTime);
    int newDir = state.movementDirection;

    // Bounce logic
    // Bounds: 0 to screenWidth - currentBlockWidth
    // Or allow overhang? The game allows moving outside, you have to tap when aligned.
    // Usually it bounces off screen edges.

    if (newX <= 0) {
      newX = 0;
      newDir = 1;
    } else if (newX + state.currentBlockWidth >= _screenWidth) {
      newX = _screenWidth - state.currentBlockWidth;
      newDir = -1;
    }

    emit(state.copyWith(currentBlockX: newX, movementDirection: newDir));
  }

  Future<void> _saveHighScore(int score) async {
    await HighScoreStore.setHighScore('towerStack_highScore', score);
  }
}
