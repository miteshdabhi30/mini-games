import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/neon_hit/bloc/neon_hit_event.dart';
import 'package:green_object/games/neon_hit/bloc/neon_hit_state.dart';
import 'package:green_object/utils/high_score_store.dart';

class NeonHitBloc extends Bloc<NeonHitEvent, NeonHitState> {
  Timer? _ticker;
  static const double _rotationSpeedBase = 0.02;

  NeonHitBloc() : super(const NeonHitState()) {
    on<GameStarted>(_onGameStarted);
    on<ThrowSpike>(_onThrowSpike);
    on<GameTick>(_onGameTick);
    on<GameReset>(_onGameReset);
  }

  void _onGameStarted(GameStarted event, Emitter<NeonHitState> emit) {
    if (state.status == GameStatus.playing) return;
    final highScore = HighScoreStore.getHighScore('neonHit_highScore');
    _startLevel(emit, 1, bonusScore: event.bonusScore, highScore: highScore);
    _startTicker();
  }

  void _onGameReset(GameReset event, Emitter<NeonHitState> emit) {
    final highScore = HighScoreStore.getHighScore('neonHit_highScore');
    _startLevel(emit, 1, bonusScore: event.bonusScore, highScore: highScore);
    _startTicker();
  }

  void _startLevel(
    Emitter<NeonHitState> emit,
    int level, {
    int bonusScore = 0,
    int? highScore,
  }) {
    emit(
      NeonHitState(
        status: GameStatus.playing,
        score: bonusScore,
        highScore: highScore ?? state.highScore,
        // Usually reset on Game Over, keep on Level Up.
        // logic handles inside onGameTick/LevelUp
        level: level,
        spikesLeft: 6 + level, // More spikes per level
        targetRotation: 0.0,
        stuckSpikes: const [],
        flyingSpikes: const [],
      ),
    );
  }

  void _onThrowSpike(ThrowSpike event, Emitter<NeonHitState> emit) {
    if (state.status != GameStatus.playing) return;
    if (state.spikesLeft <= 0) return;

    // Spawn a spike at bottom
    // We represent flying spikes by their progress or Y.
    // Simplified: Just one flying spike allowed at a time?
    // Or multiple? Knife hit allows rapid fire.
    // Let's add 0.0 to flyingSpikes.

    // Decrease ammo immediately? or on hit?
    // Usually immediately.
    emit(
      state.copyWith(
        spikesLeft: state.spikesLeft - 1,
        flyingSpikes: [...state.flyingSpikes, 0.0],
      ),
    );
  }

  void _onGameTick(GameTick event, Emitter<NeonHitState> emit) {
    if (state.status != GameStatus.playing) return;

    // 1. Rotate Target
    // Level logic: alternate direction or speed
    double speed = _rotationSpeedBase + (state.level * 0.005);
    if (state.level % 2 == 0) speed = -speed;

    double newRotation = (state.targetRotation + speed) % (2 * pi);

    // 2. Move Flying Spikes
    List<double> nextFlying = [];
    List<double> nextStuck = List.from(state.stuckSpikes);
    bool gameOver = false;
    int scoreAdded = 0;

    // Target surface is at roughly 0.8 progress (assuming 0 is bottom, 1 is center)
    const double targetHitProgress = 0.8;
    const double spikeMoveSpeed = 0.05;

    for (double progress in state.flyingSpikes) {
      double newProgress = progress + spikeMoveSpeed;

      if (newProgress >= targetHitProgress) {
        // HIT!
        // Calculate angle of impact.
        // It hits at the bottom of the circle (pi/2) relative to screen.
        // But relative to target rotation:
        // visual angle = pi/2 (90 deg, bottom)
        // target has rotated `newRotation`.
        // impale angle on target = (pi/2) - newRotation.

        double impactAngle = (pi / 2) - newRotation;
        // Normalize
        impactAngle = impactAngle % (2 * pi);
        if (impactAngle < 0) impactAngle += 2 * pi;

        // CHECK COLLISION with existing stuck spikes
        bool collision = false;
        const double captureRadius = 0.2; // roughly 12 degrees? 0.2 rad

        for (double stuckAngle in nextStuck) {
          double diff = (impactAngle - stuckAngle).abs();
          if (diff > pi) diff = 2 * pi - diff;
          if (diff < captureRadius) {
            collision = true;
            break;
          }
        }

        if (collision) {
          gameOver = true;
        } else {
          nextStuck.add(impactAngle);
          scoreAdded++;
        }
      } else {
        nextFlying.add(newProgress);
      }
    }

    if (gameOver) {
      _ticker?.cancel();
      final int nextHighScore = state.score > state.highScore
          ? state.score
          : state.highScore;
      if (nextHighScore != state.highScore) {
        HighScoreStore.setHighScore('neonHit_highScore', nextHighScore);
      }
      emit(
        state.copyWith(
          status: GameStatus.gameOver,
          stuckSpikes: nextStuck,
          highScore: nextHighScore,
        ),
      );
    } else {
      int newScore = state.score + scoreAdded;

      // Check Level Clear
      // Clear if no flying spikes and no ammo
      if (state.spikesLeft == 0 && nextFlying.isEmpty) {
        // Level Complete
        // wait a moment then start next?
        // Let's just immediately start next level for now, maybe set status LevelComplete
        _ticker?.cancel();
        // Trigger next level after delay?
        // We can do it in UI or Bloc. Bloc is safer.
        // But we can't emit multiple statuses easily without a stream.
        // Let's just reset to next level immediately.
        emit(
          state.copyWith(
            status: GameStatus.playing,
            score: newScore,
            level: state.level + 1,
            spikesLeft: 6 + state.level + 1,
            stuckSpikes: [], // Clear spikes on target
            targetRotation: 0,
          ),
        );
        _startTicker(); // restart ticker
      } else {
        emit(
          state.copyWith(
            targetRotation: newRotation,
            flyingSpikes: nextFlying,
            stuckSpikes: nextStuck,
            score: newScore,
          ),
        );
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      add(GameTick());
    });
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
