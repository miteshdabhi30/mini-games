import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/models/game_object.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'package:uuid/uuid.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  static const int lanesCount = 3;
  static const double playerSize = 50.0;
  static const double objectSize = 50.0;
  // Screen height is needed for cleanup, we'll assume a standard safe large value or pass it in.
  // Ideally, screen size should not be in logic, but we need to know when to remove objects.
  // We'll use a relative constant or pass it via event if strictly needed.
  // For now, let's assume 1000.0 as a safe cleanup threshold or handle it via UI constraints.
  // Actually, better to pass screen height or use a fixed logic coordinate system.
  // Let's use a fixed logic height of 1.0 (normalized) or similar?
  // No, let's stick to pixels for simplicity as requested, assuming a "sufficiently large" cleanup bounds.
  static const double cleanupY = 2000.0;
  static const double playerBottomPadding = 50.0;

  // We need context of screen height for collision.
  // Let's defer exact collision Y check or pass screen height in tick.
  // For simplicity refactor, I will assume a fixed height for logic or pass it.
  // Let's pass screenHeight in GameStarted or similar?
  // Actually, `GameScreen` knows height. Let's make the logic generic or
  // pass height in `GameTicked`.

  double _screenHeight = 800.0; // Default fallback

  GameBloc() : super(const GameState()) {
    on<GameStarted>(_onGameStarted);
    on<GameTicked>(_onGameTicked);
    on<PlayerMoved>(_onPlayerMoved);
    on<GameRestarted>(_onGameRestarted);
    on<GameRevived>(_onGameRevived);
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    final highScore = HighScoreStore.getHighScore('highScore');
    emit(state.copyWith(status: GameStatus.playing, highScore: highScore));
  }

  void _onGameRestarted(GameRestarted event, Emitter<GameState> emit) {
    emit(
      const GameState().copyWith(
        status: GameStatus.playing,
        highScore: state.highScore,
        score: event.bonusScore.toDouble(),
      ),
    );
  }

  void _onGameRevived(GameRevived event, Emitter<GameState> emit) {
    if (state.status != GameStatus.gameOver || state.reviveUsed) return;
    emit(
      state.copyWith(
        status: GameStatus.playing,
        reviveUsed: true,
      ),
    );
  }

  void _onPlayerMoved(PlayerMoved event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(playerLane: event.laneIndex));
  }

  void _onGameTicked(GameTicked event, Emitter<GameState> emit) {
    if (state.status != GameStatus.playing) return;

    // Use a fixed height for logic if not provided
    // In a real app we might want to pass this from UI
    // For now, valid Y range is 0 to _screenHeight

    // 1. Update Spawners
    double newTimer = state.spawnTimer + event.deltaTime;
    List<GameObject> currentObjects = List.from(state.gameObjects);
    double currentSpeed = state.speed;
    double currentInterval = state.spawnInterval;

    if (newTimer >= state.spawnInterval) {
      newTimer = 0;

      // Spawn logic
      final random = Random();
      int lane = random.nextInt(lanesCount);

      // 20% chance for Coin
      bool isCoin = random.nextDouble() < 0.2;

      currentObjects.add(
        GameObject(
          id: const Uuid().v4(),
          type: isCoin ? GameObjectType.coin : GameObjectType.obstacle,
          lane: lane,
          y: -objectSize,
        ),
      );

      // Increase difficulty
      currentSpeed += 5.0;
      currentInterval = max(0.4, currentInterval - 0.02);
    }

    // 2. Move Objects
    List<GameObject> nextObjects = [];
    double newScore = state.score + (event.deltaTime * 10);
    bool gameOver = false;
    double playerY = _screenHeight - playerSize - playerBottomPadding;

    for (var obj in currentObjects) {
      if (obj.collected) continue; // Skip collected

      double newY = obj.y + (currentSpeed * event.deltaTime);

      // Collision Detection
      // Player is at [state.playerLane]
      // Y range: [playerY, playerY + playerSize]
      // Obj Y range: [newY, newY + objectSize]

      bool collisionX = obj.lane == state.playerLane;
      bool collisionY =
          (newY < playerY + playerSize) && (newY + objectSize > playerY);

      if (collisionX && collisionY) {
        if (obj.type == GameObjectType.obstacle) {
          gameOver = true;
        } else if (obj.type == GameObjectType.coin) {
          // Collected coin
          newScore += 500; // Bonus
          // Mark as collected/remove
          continue;
        }
      }

      if (newY < cleanupY) {
        nextObjects.add(obj.copyWith(y: newY)); // Keep moving
      }
    }

    if (gameOver) {
      final int scoreValue = newScore.toInt();
      final int nextHighScore =
          scoreValue > state.highScore ? scoreValue : state.highScore;
      if (nextHighScore != state.highScore) {
        _saveHighScore(nextHighScore);
      }
      emit(
        state.copyWith(
          status: GameStatus.gameOver,
          score: newScore,
          highScore: nextHighScore,
          reviveUsed: state.reviveUsed,
          gameObjects: nextObjects, // snapshot for display
        ),
      );
    } else {
      emit(
        state.copyWith(
          gameObjects: nextObjects,
          score: newScore,
          speed: currentSpeed,
          spawnTimer: newTimer,
          spawnInterval: currentInterval,
        ),
      );
    }
  }

  Future<void> _saveHighScore(int score) async {
    await HighScoreStore.setHighScore('highScore', score);
  }

  void setScreenHeight(double height) {
    _screenHeight = height;
  }
}
