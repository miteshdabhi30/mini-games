import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TowerStackStatus { initial, playing, gameOver }

class StackBlock extends Equatable {
  final String id;
  final double x;
  final double width;
  final double y; // Visual Y position (can be relative index or pixel)
  final Color color;

  const StackBlock({
    required this.id,
    required this.x,
    required this.width,
    required this.y,
    required this.color,
  });

  @override
  List<Object> get props => [id, x, width, y, color];
}

class TowerStackState extends Equatable {
  final TowerStackStatus status;
  final List<StackBlock> stack; // Bottom to Top
  final double currentBlockX;
  final double currentBlockWidth;
  final int movementDirection; // 1 (right) or -1 (left)
  final int score;
  final int highScore;
  final double speed;
  final bool reviveUsed;

  // Game config state
  final double blockHeight;

  const TowerStackState({
    this.status = TowerStackStatus.initial,
    this.stack = const [],
    this.currentBlockX = 0,
    this.currentBlockWidth = 100,
    this.movementDirection = 1,
    this.score = 0,
    this.highScore = 0,
    this.speed = 150,
    this.reviveUsed = false,
    this.blockHeight = 40,
  });

  TowerStackState copyWith({
    TowerStackStatus? status,
    List<StackBlock>? stack,
    double? currentBlockX,
    double? currentBlockWidth,
    int? movementDirection,
    int? score,
    int? highScore,
    double? speed,
    bool? reviveUsed,
    double? blockHeight,
  }) {
    return TowerStackState(
      status: status ?? this.status,
      stack: stack ?? this.stack,
      currentBlockX: currentBlockX ?? this.currentBlockX,
      currentBlockWidth: currentBlockWidth ?? this.currentBlockWidth,
      movementDirection: movementDirection ?? this.movementDirection,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      speed: speed ?? this.speed,
      reviveUsed: reviveUsed ?? this.reviveUsed,
      blockHeight: blockHeight ?? this.blockHeight,
    );
  }

  @override
  List<Object> get props => [
    status,
    stack,
    currentBlockX,
    currentBlockWidth,
    movementDirection,
    score,
    highScore,
    speed,
    reviveUsed,
    blockHeight,
  ];
}
