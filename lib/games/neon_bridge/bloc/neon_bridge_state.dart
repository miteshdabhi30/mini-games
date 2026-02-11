import 'package:equatable/equatable.dart';

enum GameStatus {
  initial,
  waiting,
  growing,
  rotating,
  moving,
  falling,
  gameOver,
  levelUp,
}

class Platform extends Equatable {
  final double x;
  final double width;

  const Platform({required this.x, required this.width});

  @override
  List<Object> get props => [x, width];
}

class NeonBridgeState extends Equatable {
  final GameStatus status;
  final int score;
  final int highScore;
  final double bridgeHeight;
  final double bridgeAngle; // 0 is vertical up, 90 is horizontal right
  final double playerX;
  final List<Platform> platforms;

  const NeonBridgeState({
    this.status = GameStatus.initial,
    this.score = 0,
    this.highScore = 0,
    this.bridgeHeight = 0.0,
    this.bridgeAngle = 0.0,
    this.playerX = 50.0, // Start slightly inset on first platform
    this.platforms = const [],
  });

  NeonBridgeState copyWith({
    GameStatus? status,
    int? score,
    int? highScore,
    double? bridgeHeight,
    double? bridgeAngle,
    double? playerX,
    List<Platform>? platforms,
  }) {
    return NeonBridgeState(
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      bridgeHeight: bridgeHeight ?? this.bridgeHeight,
      bridgeAngle: bridgeAngle ?? this.bridgeAngle,
      playerX: playerX ?? this.playerX,
      platforms: platforms ?? this.platforms,
    );
  }

  @override
  List<Object> get props => [
    status,
    score,
    highScore,
    bridgeHeight,
    bridgeAngle,
    playerX,
    platforms,
  ];
}
