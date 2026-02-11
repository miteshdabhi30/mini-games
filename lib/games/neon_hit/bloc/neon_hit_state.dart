import 'package:equatable/equatable.dart';

enum GameStatus { initial, playing, gameOver, levelComplete }

class NeonHitState extends Equatable {
  final GameStatus status;
  final int score;
  final int highScore;
  final int level;
  final int spikesLeft;
  final double targetRotation; // Radians
  final List<double> stuckSpikes; // Angles in radians relative to target
  final List<double> flyingSpikes; // Y positions (or progress 0.0 to 1.0)

  const NeonHitState({
    this.status = GameStatus.initial,
    this.score = 0,
    this.highScore = 0,
    this.level = 1,
    this.spikesLeft = 7,
    this.targetRotation = 0.0,
    this.stuckSpikes = const [],
    this.flyingSpikes = const [],
  });

  NeonHitState copyWith({
    GameStatus? status,
    int? score,
    int? highScore,
    int? level,
    int? spikesLeft,
    double? targetRotation,
    List<double>? stuckSpikes,
    List<double>? flyingSpikes,
  }) {
    return NeonHitState(
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      level: level ?? this.level,
      spikesLeft: spikesLeft ?? this.spikesLeft,
      targetRotation: targetRotation ?? this.targetRotation,
      stuckSpikes: stuckSpikes ?? this.stuckSpikes,
      flyingSpikes: flyingSpikes ?? this.flyingSpikes,
    );
  }

  @override
  List<Object> get props => [
    status,
    score,
    highScore,
    level,
    spikesLeft,
    targetRotation,
    stuckSpikes,
    flyingSpikes,
  ];
}
