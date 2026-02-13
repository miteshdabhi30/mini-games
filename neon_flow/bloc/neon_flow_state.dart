import 'dart:math';
import 'package:equatable/equatable.dart';

enum NeonFlowStatus { initial, playing, levelCompleted }

class NeonFlowState extends Equatable {
  final NeonFlowStatus status;
  final int size;
  final List<List<int>> grid; // Static endpoints: 0=Empty, N=ColorID
  final Map<int, List<Point<int>>> paths; // Active paths
  final Map<int, List<Point<int>>> solution; // Full solution paths (for hints)
  final int? currentDrawingId; // ID of path currently being drawn
  final int level;
  final int score;
  final int highScore;
  final bool reviveUsed;

  const NeonFlowState({
    this.status = NeonFlowStatus.initial,
    this.size = 5,
    this.grid = const [],
    this.paths = const {},
    this.solution = const {},
    this.currentDrawingId,
    this.level = 1,
    this.score = 0,
    this.highScore = 0,
    this.reviveUsed = false,
  });

  NeonFlowState copyWith({
    NeonFlowStatus? status,
    int? size,
    List<List<int>>? grid,
    Map<int, List<Point<int>>>? paths,
    Map<int, List<Point<int>>>? solution,
    int? currentDrawingId,
    int? level,
    int? score,
    int? highScore,
    bool? reviveUsed,
  }) {
    return NeonFlowState(
      status: status ?? this.status,
      size: size ?? this.size,
      grid: grid ?? this.grid,
      paths: paths ?? this.paths,
      solution: solution ?? this.solution,
      currentDrawingId: currentDrawingId ?? this.currentDrawingId,
      level: level ?? this.level,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      reviveUsed: reviveUsed ?? this.reviveUsed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    size,
    grid,
    paths,
    solution,
    currentDrawingId,
    level,
    score,
    highScore,
    reviveUsed,
  ];
}
