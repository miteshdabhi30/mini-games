import 'package:equatable/equatable.dart';

enum MathRushStatus { initial, playing, correct, wrong, gameOver }

enum MathOperation { add, subtract, multiply }

enum MissingPosition { first, second, result }

class MathQuestion extends Equatable {
  final int operand1;
  final int operand2;
  final MathOperation operation;
  final MissingPosition missingPosition;
  final int correctAnswer;
  final List<int> options;

  const MathQuestion({
    required this.operand1,
    required this.operand2,
    required this.operation,
    required this.missingPosition,
    required this.correctAnswer,
    required this.options,
  });

  String get displayEquation {
    final String op = operation == MathOperation.add
        ? '+'
        : operation == MathOperation.subtract
        ? '-'
        : '×';

    final int result = operation == MathOperation.add
        ? operand1 + operand2
        : operation == MathOperation.subtract
        ? operand1 - operand2
        : operand1 * operand2;

    switch (missingPosition) {
      case MissingPosition.first:
        return '? $op $operand2 = $result';
      case MissingPosition.second:
        return '$operand1 $op ? = $result';
      case MissingPosition.result:
        return '$operand1 $op $operand2 = ?';
    }
  }

  @override
  List<Object> get props => [
    operand1,
    operand2,
    operation,
    missingPosition,
    correctAnswer,
    options,
  ];
}

class MathRushState extends Equatable {
  final MathRushStatus status;
  final MathQuestion? currentQuestion;
  final int score;
  final int highScore;
  final int level;
  final double timeRemaining;
  final double maxTime;
  final bool reviveUsed;

  const MathRushState({
    this.status = MathRushStatus.initial,
    this.currentQuestion,
    this.score = 0,
    this.highScore = 0,
    this.level = 1,
    this.timeRemaining = 5.0,
    this.maxTime = 5.0,
    this.reviveUsed = false,
  });

  MathRushState copyWith({
    MathRushStatus? status,
    MathQuestion? currentQuestion,
    int? score,
    int? highScore,
    int? level,
    double? timeRemaining,
    double? maxTime,
    bool? reviveUsed,
  }) {
    return MathRushState(
      status: status ?? this.status,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      level: level ?? this.level,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      maxTime: maxTime ?? this.maxTime,
      reviveUsed: reviveUsed ?? this.reviveUsed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentQuestion,
    score,
    highScore,
    level,
    timeRemaining,
    maxTime,
    reviveUsed,
  ];
}
