import 'package:equatable/equatable.dart';

enum NumberMergeStatus { initial, playing, gameOver }

class NumberMergeState extends Equatable {
  final NumberMergeStatus status;
  final int score;
  final int highScore;
  final List<List<int>> grid; // 5 columns x 7 rows. 0 = empty.
  final int nextNumber; // Power of 2 (2, 4, 8, 16, 32, 64)

  const NumberMergeState({
    this.status = NumberMergeStatus.initial,
    this.score = 0,
    this.highScore = 0,
    this.grid = const [],
    this.nextNumber = 2,
  });

  NumberMergeState copyWith({
    NumberMergeStatus? status,
    int? score,
    int? highScore,
    List<List<int>>? grid,
    int? nextNumber,
  }) {
    return NumberMergeState(
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      grid: grid ?? this.grid,
      nextNumber: nextNumber ?? this.nextNumber,
    );
  }

  @override
  List<Object?> get props => [status, score, highScore, grid, nextNumber];
}
