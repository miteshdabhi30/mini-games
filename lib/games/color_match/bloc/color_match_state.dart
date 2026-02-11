import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ColorMatchStatus { initial, playing, gameOver }

enum WheelColor { red, blue, green, yellow }

class FallingBall extends Equatable {
  final String id;
  final WheelColor color;
  final double y;

  const FallingBall({required this.id, required this.color, required this.y});

  FallingBall copyWith({double? y}) {
    return FallingBall(id: id, color: color, y: y ?? this.y);
  }

  Color get uiColor {
    switch (color) {
      case WheelColor.red:
        return Colors.redAccent;
      case WheelColor.blue:
        return Colors.blueAccent;
      case WheelColor.green:
        return Colors.greenAccent;
      case WheelColor.yellow:
        return Colors.amber;
    }
  }

  @override
  List<Object> get props => [id, color, y];
}

class ColorMatchState extends Equatable {
  final ColorMatchStatus status;
  final int rotationIndex; // 0..3
  final List<FallingBall> balls;
  final int score;
  final int highScore;
  final double speed;
  final double spawnTimer;
  final double spawnInterval;

  const ColorMatchState({
    this.status = ColorMatchStatus.initial,
    this.rotationIndex = 0,
    this.balls = const [],
    this.score = 0,
    this.highScore = 0,
    this.speed = 200,
    this.spawnTimer = 0,
    this.spawnInterval = 2.0,
  });

  // Top color is determined by rotationIndex.
  // Let's define the wheel segments as fixed: [Red, Blue, Green, Yellow] (Clockwise)
  // If rotationIndex is 0, Top is Red? or we just rotate the list order logic.
  // Actually, easiest is: List is [Red, Blue, Green, Yellow].
  // rotationIndex 0: Top = Red
  // rotationIndex 1: Top = Yellow (if rotating Clockwise, previous moves to top? No.)
  // Let's assume visual rotation:
  // 0 deg: Top=0
  // 90 deg: Top=3 (Counter-Clockwise rotation brings last to top?)
  // Let's stick to simple index math: `colors[rotationIndex]` is the Top color?
  // Visuals will follow logic.

  ColorMatchState copyWith({
    ColorMatchStatus? status,
    int? rotationIndex,
    List<FallingBall>? balls,
    int? score,
    int? highScore,
    double? speed,
    double? spawnTimer,
    double? spawnInterval,
  }) {
    return ColorMatchState(
      status: status ?? this.status,
      rotationIndex: rotationIndex ?? this.rotationIndex,
      balls: balls ?? this.balls,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      speed: speed ?? this.speed,
      spawnTimer: spawnTimer ?? this.spawnTimer,
      spawnInterval: spawnInterval ?? this.spawnInterval,
    );
  }

  @override
  List<Object> get props => [
    status,
    rotationIndex,
    balls,
    score,
    highScore,
    speed,
    spawnTimer,
    spawnInterval,
  ];
}
