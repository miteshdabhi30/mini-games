import 'package:flutter/material.dart';
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

class Particle extends Equatable {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double life; // 0.0 to 1.0
  final Color color;
  final double size;

  const Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
  });

  Particle copyWith({
    double? x,
    double? y,
    double? vx,
    double? vy,
    double? life,
    Color? color,
    double? size,
  }) {
    return Particle(
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      life: life ?? this.life,
      color: color ?? this.color,
      size: size ?? this.size,
    );
  }

  @override
  List<Object> get props => [x, y, vx, vy, life, color, size];
}

class NeonBridgeState extends Equatable {
  final GameStatus status;
  final int score;
  final int highScore;
  final double bridgeHeight;
  final double bridgeAngle; // 0 is vertical up, 90 is horizontal right
  final double playerX;
  final double playerY; // Vertical offset from platform level
  final List<Platform> platforms;
  final bool reviveUsed;
  final int comboCount;
  final double platformDirection; // 1.0 = right, -1.0 = left
  final List<Particle> particles;
  final double shakeOffset;

  const NeonBridgeState({
    this.status = GameStatus.initial,
    this.score = 0,
    this.highScore = 0,
    this.bridgeHeight = 0.0,
    this.bridgeAngle = 0.0,
    this.playerX = 50.0, // Start slightly inset on first platform
    this.playerY = 0.0,
    this.platforms = const [],
    this.reviveUsed = false,
    this.comboCount = 0,
    this.platformDirection = 1.0,
    this.particles = const [],
    this.shakeOffset = 0.0,
  });

  NeonBridgeState copyWith({
    GameStatus? status,
    int? score,
    int? highScore,
    double? bridgeHeight,
    double? bridgeAngle,
    double? playerX,
    double? playerY,
    List<Platform>? platforms,
    bool? reviveUsed,
    int? comboCount,
    double? platformDirection,
    List<Particle>? particles,
    double? shakeOffset,
  }) {
    return NeonBridgeState(
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      bridgeHeight: bridgeHeight ?? this.bridgeHeight,
      bridgeAngle: bridgeAngle ?? this.bridgeAngle,
      playerX: playerX ?? this.playerX,
      playerY: playerY ?? this.playerY,
      platforms: platforms ?? this.platforms,
      reviveUsed: reviveUsed ?? this.reviveUsed,
      comboCount: comboCount ?? this.comboCount,
      platformDirection: platformDirection ?? this.platformDirection,
      particles: particles ?? this.particles,
      shakeOffset: shakeOffset ?? this.shakeOffset,
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
    playerY,
    platforms,
    reviveUsed,
    comboCount,
    platformDirection,
    particles,
    shakeOffset,
  ];
}
