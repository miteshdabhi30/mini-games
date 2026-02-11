import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'neon_loop_event.dart';
import 'neon_loop_state.dart';

class NeonLoopBloc extends Bloc<NeonLoopEvent, NeonLoopState> {
  final Random _random = Random();

  NeonLoopBloc() : super(const NeonLoopState()) {
    on<NeonLoopStarted>(_onStarted);
    on<NeonLoopTicked>(_onTicked);
    on<NeonLoopTapped>(_onTapped);
    on<NeonLoopRestarted>(_onRestarted);
  }

  Future<void> _onStarted(
    NeonLoopStarted event,
    Emitter<NeonLoopState> emit,
  ) async {
    final highScore = HighScoreStore.getHighScore('neonLoop_highScore');
    emit(
      state.copyWith(
        status: NeonLoopStatus.playing,
        highScore: highScore,
        targetAngle: _random.nextDouble() * 2 * pi,
      ),
    );
  }

  void _onTicked(NeonLoopTicked event, Emitter<NeonLoopState> emit) {
    if (state.status != NeonLoopStatus.playing) return;

    double newAngle = state.ballAngle + (state.rotationSpeed * event.deltaTime);
    // Normalize angle to 0..2*pi
    newAngle %= (2 * pi);
    if (newAngle < 0) newAngle += (2 * pi);

    emit(state.copyWith(ballAngle: newAngle));
  }

  Future<void> _onTapped(
    NeonLoopTapped event,
    Emitter<NeonLoopState> emit,
  ) async {
    if (state.status != NeonLoopStatus.playing) return;

    // Check hit
    // Normalize targetAngle vs ballAngle
    double diff = (state.ballAngle - state.targetAngle).abs();
    // Wrap around check
    if (diff > pi) diff = (2 * pi) - diff;

    final bool isHit = diff <= (state.targetWidth / 2);

    if (isHit) {
      final newScore = state.score + 1;
      // Reverse and speed up
      double newSpeed = state.rotationSpeed * -1.05; // 5% increase each hit

      // Cap max speed
      if (newSpeed.abs() > 10.0) {
        newSpeed = 10.0 * (newSpeed.sign);
      }

      // New target far enough from current position
      double newTarget;
      do {
        newTarget = _random.nextDouble() * 2 * pi;
        double targetDiff = (newTarget - state.ballAngle).abs();
        if (targetDiff > pi) targetDiff = (2 * pi) - targetDiff;
        if (targetDiff > 1.0) break; // At least 1 radian away
      } while (true);

      // Make target narrower gradually
      double nextWidth = max(0.2, 0.5 - (newScore * 0.005));

      emit(
        state.copyWith(
          score: newScore,
          rotationSpeed: newSpeed,
          targetAngle: newTarget,
          targetWidth: nextWidth,
        ),
      );
    } else {
      // Game Over
      final nextHighScore = state.score > state.highScore
          ? state.score
          : state.highScore;
      if (nextHighScore != state.highScore) {
        await HighScoreStore.setHighScore('neonLoop_highScore', nextHighScore);
      }
      emit(
        state.copyWith(
          status: NeonLoopStatus.gameOver,
          highScore: nextHighScore,
        ),
      );
    }
  }

  void _onRestarted(NeonLoopRestarted event, Emitter<NeonLoopState> emit) {
    emit(
      NeonLoopState(
        highScore: state.highScore,
        score: event.bonusScore,
        targetAngle: _random.nextDouble() * 2 * pi,
      ),
    );
  }
}
