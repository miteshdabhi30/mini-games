import 'package:equatable/equatable.dart';

enum PatternMatchStatus { idle, showingPattern, playerTurn, gameOver }

class PatternMatchState extends Equatable {
  final PatternMatchStatus status;
  final List<int> pattern;
  final List<int> playerInput;
  final int currentRound;
  final int score;
  final int highScore;
  final int? highlightedButton;

  const PatternMatchState({
    this.status = PatternMatchStatus.idle,
    this.pattern = const [],
    this.playerInput = const [],
    this.currentRound = 1,
    this.score = 0,
    this.highScore = 0,
    this.highlightedButton,
  });

  PatternMatchState copyWith({
    PatternMatchStatus? status,
    List<int>? pattern,
    List<int>? playerInput,
    int? currentRound,
    int? score,
    int? highScore,
    int? highlightedButton,
  }) {
    return PatternMatchState(
      status: status ?? this.status,
      pattern: pattern ?? this.pattern,
      playerInput: playerInput ?? this.playerInput,
      currentRound: currentRound ?? this.currentRound,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      highlightedButton: highlightedButton,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pattern,
    playerInput,
    currentRound,
    score,
    highScore,
    highlightedButton,
  ];
}
