import 'dart:async';
import 'dart:math';
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
  }

  void _onGameStarted(GameStarted event, Emitter<NeonBridgeState> emit) {
    _resetGame(emit, bonusScore: event.bonusScore);
  }

  void _onGameReset(GameReset event, Emitter<NeonBridgeState> emit) {
    _resetGame(emit, bonusScore: event.bonusScore);
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
    if (state.status == GameStatus.growing) {
      emit(state.copyWith(bridgeHeight: state.bridgeHeight + _growSpeed));
    } else if (state.status == GameStatus.rotating) {
      double newAngle = state.bridgeAngle + _rotateSpeed;
      if (newAngle >= 90) {
        newAngle = 90;
        emit(state.copyWith(bridgeAngle: newAngle, status: GameStatus.moving));
      } else {
        emit(state.copyWith(bridgeAngle: newAngle));
      }
    } else if (state.status == GameStatus.moving) {
      _handleMoving(emit);
    } else if (state.status == GameStatus.falling) {
      // Fall animation logic simply waits for reset or handled by UI animation usually
      // For now, if falling, we just transition to Game Over after a moment or handle Y in UI
      // Let's just switch to GameOver immediately for simplicity in Bloc
      final int nextHighScore = state.score > state.highScore
          ? state.score
          : state.highScore;
      if (nextHighScore != state.highScore) {
        HighScoreStore.setHighScore('neonBridge_highScore', nextHighScore);
      }
      emit(
        state.copyWith(status: GameStatus.gameOver, highScore: nextHighScore),
      );
      _ticker?.cancel();
    } else if (state.status == GameStatus.levelUp) {
      // Shift platforms
      List<Platform> current = List.from(state.platforms);
      // Move everything left so player is on first platform again?
      // Or just generate next platform.
      // Let's scroll the world.
      // Actually simpler: Move player to end of bridge, then spawn new platform, then scroll.
      // For this step, let's just create next platform and reset player/bridge relative to new view.

      // Remove first platform, kept second as new first.
      Platform oldSecond = current[1];
      Platform newFirst = Platform(x: 0, width: oldSecond.width);

      double distance = 50 + _random.nextDouble() * 150;
      distance = distance - (state.score * 2); // Harder as you go
      if (distance < 20) distance = 20;

      double width = 40 + _random.nextDouble() * 60;
      width = width - (state.score);
      if (width < 20) width = 20;

      Platform newSecond = Platform(x: newFirst.width + distance, width: width);

      emit(
        state.copyWith(
          status: GameStatus.waiting,
          platforms: [newFirst, newSecond],
          playerX: newFirst.width - 20,
          bridgeHeight: 0,
          bridgeAngle: 0,
        ),
      );
    }
  }

  void _handleMoving(Emitter<NeonBridgeState> emit) {
    double moveDist = _moveSpeed;
    double newX = state.playerX + moveDist;

    // Target calculation
    Platform current = state.platforms[0];
    Platform target = state.platforms[1];

    // Bridge start X is current.width (assumed local coordinate 0 is start of first platform?
    // No, x is global.
    // Platform 0 is at x=0.
    // Bridge starts at currentPlatform.x + width.
    double bridgeStart = current.x + current.width;
    double bridgeEnd = bridgeStart + state.bridgeHeight;

    // Check destination
    // If player crossed the bridge
    if (newX >= bridgeEnd) {
      newX = bridgeEnd; // Snap to end

      // Check if land is successful
      bool success =
          bridgeEnd >= target.x && bridgeEnd <= (target.x + target.width);

      if (success) {
        // Move to center of target? or just edge.
        // Let's walk fully onto target.
        // For now, stop at tip of bridge/start of platform, then Level Up.
        emit(
          state.copyWith(
            playerX:
                target.x + target.width - 20, // Walk to end of next platform
            score: state.score + 1,
            status: GameStatus.levelUp,
          ),
        );
      } else {
        // Fall
        emit(state.copyWith(playerX: newX, status: GameStatus.falling));
      }
    } else {
      emit(state.copyWith(playerX: newX));
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
