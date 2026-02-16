import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/games/neon_bridge/bloc/neon_bridge_event.dart';
import 'package:green_object/games/neon_bridge/bloc/neon_bridge_state.dart';
import 'package:green_object/utils/high_score_store.dart';

class NeonBridgeBloc extends Bloc<NeonBridgeEvent, NeonBridgeState> {
  Timer? _ticker;
  final Random _random = Random();

  static const double _growSpeed = 5.0;
  static const double _rotateSpeed = 5.0; // degrees per tick
  static const double _moveSpeed = 8.0;

  NeonBridgeBloc() : super(const NeonBridgeState()) {
    on<GameStarted>(_onGameStarted);
    on<StartGrow>(_onStartGrow);
    on<StopGrow>(_onStopGrow);
    on<GameTick>(_onGameTick);
    on<GameReset>(_onGameReset);
    on<GameRevived>(_onRevived);
  }

  void _onGameStarted(GameStarted event, Emitter<NeonBridgeState> emit) {
    _resetGame(emit, bonusScore: event.bonusScore);
  }

  void _onGameReset(GameReset event, Emitter<NeonBridgeState> emit) {
    _resetGame(emit, bonusScore: event.bonusScore);
  }

  void _onRevived(GameRevived event, Emitter<NeonBridgeState> emit) {
    if (state.status != GameStatus.gameOver || state.reviveUsed) return;

    emit(
      state.copyWith(
        status: GameStatus.waiting,
        bridgeHeight: 0,
        bridgeAngle: 0,
        reviveUsed: true,
        playerX: state.platforms[0].width - 20,
      ),
    );
    _startTicker();
  }

  void _resetGame(Emitter<NeonBridgeState> emit, {int bonusScore = 0}) {
    _ticker?.cancel();
    // Initial platforms: one at start, one random
    final first = const Platform(x: 0, width: 80);
    final distance = 50 + _random.nextDouble() * 150;
    final width = 40 + _random.nextDouble() * 60;
    final second = Platform(x: first.width + distance, width: width);
    final highScore = HighScoreStore.getHighScore('neonBridge_highScore');

    emit(
      NeonBridgeState(
        status: GameStatus.waiting,
        score: bonusScore,
        highScore: highScore,
        platforms: [first, second],
        playerX: first.width - 20, // Near edge
        playerY: 0,
        particles: [],
        shakeOffset: 0,
      ),
    );
    _startTicker();
  }

  void _onStartGrow(StartGrow event, Emitter<NeonBridgeState> emit) {
    if (state.status == GameStatus.waiting) {
      emit(state.copyWith(status: GameStatus.growing));
    }
  }

  void _onStopGrow(StopGrow event, Emitter<NeonBridgeState> emit) {
    if (state.status == GameStatus.growing) {
      emit(state.copyWith(status: GameStatus.rotating));
    }
  }

  void _onGameTick(GameTick event, Emitter<NeonBridgeState> emit) {
    // 1. Update Particles
    List<Particle> updatedParticles = [];
    if (state.particles.isNotEmpty) {
      for (final p in state.particles) {
        if (p.life > 0) {
          updatedParticles.add(
            p.copyWith(
              x: p.x + p.vx,
              y: p.y + p.vy,
              life: p.life - 0.02, // Fade out
              vy: p.vy + 0.1, // Gravity
            ),
          );
        }
      }
    }

    // 2. Update Shake
    double newShake = 0;
    if (state.shakeOffset > 0) {
      newShake = state.shakeOffset * 0.9; // Decay
      if (newShake < 0.5) newShake = 0;
    }

    // 3. New State base
    NeonBridgeState newState = state.copyWith(
      particles: updatedParticles,
      shakeOffset: newShake,
    );

    // Apply new base state before logic (logic might override parts of it)
    // Actually simpler to just define variables and emit once at end or use a holder.
    // Since logic branches, we'll have to be careful.
    // Let's use `newState` as the basis for further modifications.

    if (newState.status == GameStatus.waiting) {
      _handleWaiting(emit, newState);
    } else if (newState.status == GameStatus.growing) {
      emit(newState.copyWith(bridgeHeight: state.bridgeHeight + _growSpeed));
    } else if (newState.status == GameStatus.rotating) {
      double newAngle = state.bridgeAngle + _rotateSpeed;
      if (newAngle >= 90) {
        newAngle = 90;
        emit(
          newState.copyWith(bridgeAngle: newAngle, status: GameStatus.moving),
        );
      } else {
        emit(newState.copyWith(bridgeAngle: newAngle));
      }
    } else if (newState.status == GameStatus.moving) {
      _handleMoving(emit, newState);
    } else if (newState.status == GameStatus.falling) {
      _handleFalling(emit, newState);
    } else if (newState.status == GameStatus.levelUp) {
      _handleLevelUp(emit, newState);
    } else {
      // Just emit updates (particles/shake) if no specific logic
      emit(newState);
    }
  }

  void _handleWaiting(
    Emitter<NeonBridgeState> emit,
    NeonBridgeState baseState,
  ) {
    // Platform Movement Logic (Only if Score > 5)
    if (baseState.score > 5 && baseState.platforms.length > 1) {
      final screenWidth = 400.0; // Approximate, safe bound
      final target = baseState.platforms[1];
      final first = baseState.platforms[0];

      // Determine Speed based on Score
      double speed = 2.0;
      if (baseState.score > 10) speed = 3.5;
      if (baseState.score > 20) speed = 5.0;

      double newX = target.x + (baseState.platformDirection * speed);

      // Ping Pong Boundaries
      double minX = first.x + first.width + 20; // Closest gap
      double maxX = minX + 250; // Max gap

      double newDirection = baseState.platformDirection;

      if (newX <= minX) {
        newX = minX;
        newDirection = 1.0;
      } else if (newX >= maxX) {
        newX = maxX;
        newDirection = -1.0;
      }

      // Update Platform Position
      final newPlatform = Platform(x: newX, width: target.width);
      final newPlatforms = [first, newPlatform];

      emit(
        baseState.copyWith(
          platforms: newPlatforms,
          platformDirection: newDirection,
        ),
      );
    } else {
      emit(baseState);
    }
  }

  void _handleFalling(
    Emitter<NeonBridgeState> emit,
    NeonBridgeState baseState,
  ) {
    double newY = baseState.playerY + 10.0; // Gravity

    if (newY > 300) {
      // Fell off screen
      final int nextHighScore = baseState.score > baseState.highScore
          ? baseState.score
          : baseState.highScore;
      if (nextHighScore != baseState.highScore) {
        HighScoreStore.setHighScore('neonBridge_highScore', nextHighScore);
      }
      emit(
        baseState.copyWith(
          status: GameStatus.gameOver,
          highScore: nextHighScore,
        ),
      );
      _ticker?.cancel();
    } else {
      emit(baseState.copyWith(playerY: newY));
    }
  }

  void _handleLevelUp(
    Emitter<NeonBridgeState> emit,
    NeonBridgeState baseState,
  ) {
    // Shift platforms
    List<Platform> current = List.from(baseState.platforms);

    Platform oldSecond = current[1];
    Platform newFirst = Platform(x: 0, width: oldSecond.width);

    double distance = 50 + _random.nextDouble() * 150;
    if (distance < 20) distance = 20;

    double width = 40 + _random.nextDouble() * 60;
    if (width < 20) width = 20;

    Platform newSecond = Platform(x: newFirst.width + distance, width: width);

    emit(
      baseState.copyWith(
        status: GameStatus.waiting,
        platforms: [newFirst, newSecond],
        playerX: newFirst.width - 20,
        bridgeHeight: 0,
        bridgeAngle: 0,
        playerY: 0,
      ),
    );
  }

  void _handleMoving(Emitter<NeonBridgeState> emit, NeonBridgeState baseState) {
    double moveDist = _moveSpeed;
    double newX = baseState.playerX + moveDist;

    // Target calculation
    Platform current = baseState.platforms[0];
    Platform target = baseState.platforms[1];

    double bridgeStart = current.x + current.width;
    double bridgeEnd = bridgeStart + baseState.bridgeHeight;

    // Check destination
    // If player crossed the bridge
    if (newX >= bridgeEnd) {
      newX = bridgeEnd; // Snap to end

      // Check if land is successful
      bool success =
          bridgeEnd >= target.x && bridgeEnd <= (target.x + target.width);

      if (success) {
        // Perfect Landing Check
        // Center of target
        double targetCenter = target.x + (target.width / 2);
        double tolerance = 6.0; // Slightly loosened for better feel

        bool isPerfect = (bridgeEnd - targetCenter).abs() <= tolerance;
        int combo = baseState.comboCount;
        int scoreToAdd = 1;

        List<Particle> newParticles = List.from(baseState.particles);
        double newShake = baseState.shakeOffset;

        if (isPerfect) {
          combo++;
          scoreToAdd = 1 + combo; // Reward increases with combo
          newShake = 10.0; // Big shake

          // Explosion particles
          for (int i = 0; i < 20; i++) {
            double angle = _random.nextDouble() * 2 * pi;
            double speed = 2 + _random.nextDouble() * 3;
            newParticles.add(
              Particle(
                x: bridgeEnd,
                y: 0, // Relative to platform top (handled in painter)
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - 2, // Upward bias
                life: 1.0,
                color:
                    Colors.primaries[_random.nextInt(Colors.primaries.length)],
                size: 3 + _random.nextDouble() * 4,
              ),
            );
          }
        } else {
          combo = 0; // Reset combo if not perfect
          newShake = 2.0; // Small thud
        }

        // Walk to end of next platform (UI handles animation interpolation usually, but here we jump for now)
        // We will keep player at bridgeEnd for a moment then LevelUp?
        // Current logic snaps to end of next platform.
        // Let's improve: Snap to bridge end, then LevelUp logic shifts world.

        emit(
          baseState.copyWith(
            playerX: target.x + target.width - 20,
            score: baseState.score + scoreToAdd,
            comboCount: combo,
            status: GameStatus.levelUp,
            particles: newParticles,
            shakeOffset: newShake,
          ),
        );
      } else {
        // Fall
        emit(
          baseState.copyWith(
            playerX: newX,
            status: GameStatus.falling,
            comboCount: 0,
          ),
        );
      }
    } else {
      emit(baseState.copyWith(playerX: newX));
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
