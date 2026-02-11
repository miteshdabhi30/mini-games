import 'package:equatable/equatable.dart';

enum NeonLoopStatus { playing, gameOver }

class NeonLoopState extends Equatable {
  final NeonLoopStatus status;
  final double ballAngle; // 0 to 2*pi
  final double targetAngle; // center of target
  final double targetWidth; // total width in radians
  final double rotationSpeed; // radians per second
  final int score;
  final int highScore;

  const NeonLoopState({
    this.status = NeonLoopStatus.playing,
    this.ballAngle = 0,
    this.targetAngle = 0,
    this.targetWidth = 0.5, // ~28 degrees
    this.rotationSpeed = 3.0,
    this.score = 0,
    this.highScore = 0,
  });

  NeonLoopState copyWith({
    NeonLoopStatus? status,
    double? ballAngle,
    double? targetAngle,
    double? targetWidth,
    double? rotationSpeed,
    int? score,
    int? highScore,
  }) {
    return NeonLoopState(
      status: status ?? this.status,
      ballAngle: ballAngle ?? this.ballAngle,
      targetAngle: targetAngle ?? this.targetAngle,
      targetWidth: targetWidth ?? this.targetWidth,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
    );
  }

  @override
  List<Object?> get props => [
    status,
    ballAngle,
    targetAngle,
    targetWidth,
    rotationSpeed,
    score,
    highScore,
  ];
}
