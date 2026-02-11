import 'package:equatable/equatable.dart';

enum SnakeStatus { initial, playing, gameOver }

class SnakePoint extends Equatable {
  final int x;
  final int y;

  const SnakePoint(this.x, this.y);

  @override
  List<Object> get props => [x, y];
}

class SnakeState extends Equatable {
  final SnakeStatus status;
  final List<SnakePoint> snake; // 0 is Head
  final SnakePoint food;
  final int dx;
  final int dy;
  final int score;
  final int highScore;

  // Grid Config
  final int columns;
  final int rows;

  // Movement
  final double moveTimer;
  final double moveInterval; // Speed

  const SnakeState({
    this.status = SnakeStatus.initial,
    this.snake = const [],
    this.food = const SnakePoint(0, 0),
    this.dx = 0,
    this.dy = 1,
    this.score = 0,
    this.highScore = 0,
    this.columns = 20,
    this.rows =
        30, // Dynamic based on screen? Let's fix grid size for simplicity or calculate.
    this.moveTimer = 0,
    this.moveInterval = 0.15,
  });

  SnakeState copyWith({
    SnakeStatus? status,
    List<SnakePoint>? snake,
    SnakePoint? food,
    int? dx,
    int? dy,
    int? score,
    int? highScore,
    int? columns,
    int? rows,
    double? moveTimer,
    double? moveInterval,
  }) {
    return SnakeState(
      status: status ?? this.status,
      snake: snake ?? this.snake,
      food: food ?? this.food,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      moveTimer: moveTimer ?? this.moveTimer,
      moveInterval: moveInterval ?? this.moveInterval,
    );
  }

  @override
  List<Object> get props => [
    status,
    snake,
    food,
    dx,
    dy,
    score,
    highScore,
    columns,
    rows,
    moveTimer,
    moveInterval,
  ];
}
