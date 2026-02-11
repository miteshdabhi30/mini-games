part of 'game_bloc.dart';

enum GameStatus { initial, playing, gameOver }

class GameState extends Equatable {
  final GameStatus status;
  final int playerLane;
  final List<GameObject> gameObjects;
  final double score;
  final int highScore;
  final double speed;
  final bool reviveUsed;

  // Internal state for spawning
  final double spawnTimer;
  final double spawnInterval;

  const GameState({
    this.status = GameStatus.initial,
    this.playerLane = 1,
    this.gameObjects = const [],
    this.score = 0,
    this.highScore = 0,
    this.speed = 300,
    this.reviveUsed = false,
    this.spawnTimer = 0,
    this.spawnInterval = 1.5,
  });

  GameState copyWith({
    GameStatus? status,
    int? playerLane,
    List<GameObject>? gameObjects,
    double? score,
    int? highScore,
    double? speed,
    bool? reviveUsed,
    double? spawnTimer,
    double? spawnInterval,
  }) {
    return GameState(
      status: status ?? this.status,
      playerLane: playerLane ?? this.playerLane,
      gameObjects: gameObjects ?? this.gameObjects,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      speed: speed ?? this.speed,
      reviveUsed: reviveUsed ?? this.reviveUsed,
      spawnTimer: spawnTimer ?? this.spawnTimer,
      spawnInterval: spawnInterval ?? this.spawnInterval,
    );
  }

  @override
  List<Object> get props => [
    status,
    playerLane,
    gameObjects,
    score,
    highScore,
    speed,
    reviveUsed,
    spawnTimer,
    spawnInterval,
  ];
}
