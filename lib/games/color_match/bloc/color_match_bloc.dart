import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'package:uuid/uuid.dart';
import 'color_match_event.dart';
import 'color_match_state.dart';

class ColorMatchBloc extends Bloc<ColorMatchEvent, ColorMatchState> {
  // Config
  static const List<WheelColor> wheelColors = [
    WheelColor.red,
    WheelColor.blue,
    WheelColor.green,
    WheelColor.yellow,
  ];

  double _screenHeight = 800.0;
  static const double wheelRadius = 50.0;
  static const double ballRadius = 15.0;
  // If wheel is at bottom center, its center Y is roughly screenHeight - 100
  // We match when ball hits the top of the wheel.

  ColorMatchBloc() : super(const ColorMatchState()) {
    on<ColorMatchStarted>(_onStarted);
    on<ColorMatchTicked>(_onTicked);
    on<ColorMatchRotated>(_onRotated);
    on<ColorMatchRestarted>(_onRestarted);
  }

  void setScreenHeight(double h) => _screenHeight = h;

  Future<void> _onStarted(
    ColorMatchStarted event,
    Emitter<ColorMatchState> emit,
  ) async {
    final highScore = HighScoreStore.getHighScore('colorMatch_highScore');
    emit(
      state.copyWith(
        status: ColorMatchStatus.playing,
        highScore: highScore,
        score: event.bonusScore,
      ),
    );
  }

  void _onRestarted(ColorMatchRestarted event, Emitter<ColorMatchState> emit) {
    emit(
      state.copyWith(
        status: ColorMatchStatus.playing,
        balls: [],
        score: event.bonusScore,
        rotationIndex: 0,
        speed: 200,
        spawnInterval: 2.0,
        spawnTimer: 0,
      ),
    );
  }

  void _onRotated(ColorMatchRotated event, Emitter<ColorMatchState> emit) {
    if (state.status != ColorMatchStatus.playing) return;
    // Rotate Clockwise: 0 -> 1 -> 2 -> 3 -> 0
    // Actually, usually 4 colors, tap moves to next.
    emit(state.copyWith(rotationIndex: (state.rotationIndex + 1) % 4));
  }

  void _onTicked(ColorMatchTicked event, Emitter<ColorMatchState> emit) {
    if (state.status != ColorMatchStatus.playing) return;

    // 1. Spawn
    double newTimer = state.spawnTimer + event.deltaTime;
    double currentInterval = state.spawnInterval;
    double currentSpeed = state.speed;
    List<FallingBall> currentBalls = List.from(state.balls);

    if (newTimer >= currentInterval) {
      newTimer = 0;
      final random = Random();
      final color = wheelColors[random.nextInt(4)];
      currentBalls.add(
        FallingBall(
          id: const Uuid().v4(),
          color: color,
          y: -30.0, // Start above screen
        ),
      );

      // Difficulty
      currentSpeed += 2.0;
      currentInterval = max(0.6, currentInterval - 0.05);
    }

    // 2. Move & Collide
    List<FallingBall> nextBalls = [];
    bool gameOver = false;
    int newScore = state.score;

    // Geometry
    // Wheel is at bottom, say center (ScreenW/2, ScreenH - 100)
    // Ball falls at ScreenW/2
    // Hit Y = (ScreenH - 100) - wheelRadius - ballRadius roughly.
    // Let's assume logic Y is just pixels from top.
    final double targetY = _screenHeight - 150.0; // Approximation

    for (var ball in currentBalls) {
      double newY = ball.y + (currentSpeed * event.deltaTime);

      // Check collision
      if (newY >= targetY) {
        // HIT!
        // Check match
        // Active color is wheelColors[state.rotationIndex] ??
        // IMPORTANT: We need to define which index is facing UP.
        // Let's say rotationIndex 0 => Index 0 is UP.
        // rotationIndex 1 => Index 3 is UP (if rotating one way) or Index 1?
        // Let's assume the wheel list is fixed [R, B, G, Y].
        // visual rotation draws this list rotated by angle.
        // If we rotate physical list:
        // Top Color is basically: wheelColors[(0 - state.rotationIndex) % 4]?
        // No, simpler:
        // activeColor = wheelColors[state.rotationIndex] logic:
        // Tap -> rotates wheel so Next Color faces up.
        // Let's define: activeColor = wheelColors[state.rotationIndex].
        // UI just draws wheelColors[state.rotationIndex] at the top.

        final activeColor = wheelColors[state.rotationIndex];

        if (ball.color == activeColor) {
          // Match!
          newScore += 10;
          // Remove ball
          continue;
        } else {
          // Mismatch
          gameOver = true;
          break;
        }
      } else {
        nextBalls.add(ball.copyWith(y: newY));
      }
    }

    if (gameOver) {
      final int nextHighScore =
          newScore > state.highScore ? newScore : state.highScore;
      if (nextHighScore != state.highScore) {
        _saveHighScore(nextHighScore);
      }
      emit(
        state.copyWith(
          status: ColorMatchStatus.gameOver,
          score: newScore,
          highScore: nextHighScore,
          balls: nextBalls,
        ),
      );
    } else {
      emit(
        state.copyWith(
          balls: nextBalls,
          score: newScore,
          spawnTimer: newTimer,
          speed: currentSpeed,
          spawnInterval: currentInterval,
        ),
      );
    }
  }

  Future<void> _saveHighScore(int score) async {
    await HighScoreStore.setHighScore('colorMatch_highScore', score);
  }
}
