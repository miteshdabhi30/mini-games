import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'snake_event.dart';
import 'snake_state.dart';

class SnakeBloc extends Bloc<SnakeEvent, SnakeState> {
  static const int gridColumns = 20;
  static const int gridRows = 30; // Logical grid size

  SnakeBloc() : super(const SnakeState(columns: gridColumns, rows: gridRows)) {
    on<SnakeStarted>(_onStarted);
    on<SnakeTicked>(_onTicked);
    on<SnakeDirectionChanged>(_onDirectionChanged);
    on<SnakeRestarted>(_onRestarted);
    on<SnakeRevived>(_onRevived);
  }

  Future<void> _onStarted(SnakeStarted event, Emitter<SnakeState> emit) async {
    final highScore = HighScoreStore.getHighScore('snake_highScore');

    // Initial Snake: Length 3, Center
    final startX = gridColumns ~/ 2;
    final startY = gridRows ~/ 2;
    final snake = [
      SnakePoint(startX, startY),
      SnakePoint(startX, startY - 1),
      SnakePoint(startX, startY - 2),
    ];

    emit(
      state.copyWith(
        status: SnakeStatus.playing,
        highScore: highScore,
        snake: snake,
        food: _generateFood(snake),
        dx: 0,
        dy: 1, // Moving down
        score: event.bonusScore,
        moveInterval: 0.15,
        reviveUsed: false,
      ),
    );
  }

  void _onRevived(SnakeRevived event, Emitter<SnakeState> emit) {
    if (state.status != SnakeStatus.gameOver || state.reviveUsed) return;

    // Revive Logic: Reset snake to center, length 3, keep score
    final startX = gridColumns ~/ 2;
    final startY = gridRows ~/ 2;
    final snake = [
      SnakePoint(startX, startY),
      SnakePoint(startX, startY - 1),
      SnakePoint(startX, startY - 2),
    ];

    emit(
      state.copyWith(
        status: SnakeStatus.playing,
        snake: snake,
        food: _generateFood(snake),
        dx: 0,
        dy: 1,
        reviveUsed: true,
      ),
    );
  }

  void _onRestarted(SnakeRestarted event, Emitter<SnakeState> emit) {
    add(SnakeStarted(bonusScore: event.bonusScore)); // Reuse start logic
  }

  void _onDirectionChanged(
    SnakeDirectionChanged event,
    Emitter<SnakeState> emit,
  ) {
    if (state.status != SnakeStatus.playing) return;

    // Prevent immediate reversal
    if (state.dx != 0 && event.dx == -state.dx) return;
    if (state.dy != 0 && event.dy == -state.dy) return;

    emit(state.copyWith(dx: event.dx, dy: event.dy));
  }

  void _onTicked(SnakeTicked event, Emitter<SnakeState> emit) {
    if (state.status != SnakeStatus.playing) return;

    double newTimer = state.moveTimer + event.deltaTime;
    if (newTimer < state.moveInterval) {
      emit(state.copyWith(moveTimer: newTimer));
      return;
    }

    // Move Step
    final head = state.snake.first;
    final newHead = SnakePoint(head.x + state.dx, head.y + state.dy);

    // Check Collision (Walls)
    if (newHead.x < 0 ||
        newHead.x >= gridColumns ||
        newHead.y < 0 ||
        newHead.y >= gridRows) {
      _gameOver(emit);
      return;
    }

    // Check Collision (Self)
    // We check against the entire snake. If we hit the tail, it's game over
    // because the snake grows if it eats food, so the tail position is occupied.
    bool selfCollision = false;
    for (final point in state.snake) {
      if (point == newHead) {
        selfCollision = true;
        break;
      }
    }

    if (selfCollision) {
      _gameOver(emit);
      return;
    }

    List<SnakePoint> newSnake = [newHead, ...state.snake];

    // Check Food
    bool ateFood = (newHead == state.food);
    int newScore = state.score;
    SnakePoint newFood = state.food;
    double newInterval = state.moveInterval;

    if (ateFood) {
      newScore += 10;
      newFood = _generateFood(newSnake);
      // Speed up: faster initial drop, then slowing down at higher speeds
      // Start 0.15, min 0.04
      newInterval = max(0.04, 0.15 * pow(0.97, newScore ~/ 10));
    } else {
      newSnake.removeLast();
    }

    emit(
      state.copyWith(
        snake: newSnake,
        food: newFood,
        score: newScore,
        moveTimer: 0,
        moveInterval: newInterval,
      ),
    );
  }

  void _gameOver(Emitter<SnakeState> emit) {
    final int nextHighScore = state.score > state.highScore
        ? state.score
        : state.highScore;
    if (nextHighScore != state.highScore) {
      _saveHighScore(nextHighScore);
    }
    emit(
      state.copyWith(status: SnakeStatus.gameOver, highScore: nextHighScore),
    );
  }

  SnakePoint _generateFood(List<SnakePoint> currentSnake) {
    final random = Random();
    int x, y;
    while (true) {
      x = random.nextInt(gridColumns);
      y = random.nextInt(gridRows);
      final point = SnakePoint(x, y);
      if (!currentSnake.contains(point)) {
        return point;
      }
    }
  }

  Future<void> _saveHighScore(int score) async {
    await HighScoreStore.setHighScore('snake_highScore', score);
  }
}
