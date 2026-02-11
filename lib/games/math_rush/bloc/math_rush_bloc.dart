import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'math_rush_event.dart';
import 'math_rush_state.dart';

class MathRushBloc extends Bloc<MathRushEvent, MathRushState> {
  final Random _random = Random();

  MathRushBloc() : super(const MathRushState()) {
    on<MathRushStarted>(_onStarted);
    on<MathRushTicked>(_onTicked);
    on<MathRushAnswered>(_onAnswered);
    on<MathRushRestarted>(_onRestarted);
  }

  Future<void> _onStarted(
    MathRushStarted event,
    Emitter<MathRushState> emit,
  ) async {
    final highScore = HighScoreStore.getHighScore('mathRush_highScore');
    final question = _generateQuestion(1);

    emit(
      state.copyWith(
        status: MathRushStatus.playing,
        highScore: highScore,
        score: event.bonusScore,
        level: 1,
        currentQuestion: question,
        timeRemaining: 5.0,
        maxTime: 5.0,
      ),
    );
  }

  void _onRestarted(MathRushRestarted event, Emitter<MathRushState> emit) {
    final question = _generateQuestion(1);

    emit(
      state.copyWith(
        status: MathRushStatus.playing,
        score: event.bonusScore,
        level: 1,
        currentQuestion: question,
        timeRemaining: 5.0,
        maxTime: 5.0,
      ),
    );
  }

  void _onTicked(MathRushTicked event, Emitter<MathRushState> emit) {
    if (state.status != MathRushStatus.playing) return;

    final newTime = state.timeRemaining - event.deltaTime;

    if (newTime <= 0) {
      // Time's up - game over
      final int nextHighScore = state.score > state.highScore
          ? state.score
          : state.highScore;
      if (nextHighScore != state.highScore) {
        _saveHighScore(nextHighScore);
      }

      emit(
        state.copyWith(
          status: MathRushStatus.gameOver,
          timeRemaining: 0,
          highScore: nextHighScore,
        ),
      );
    } else {
      emit(state.copyWith(timeRemaining: newTime));
    }
  }

  Future<void> _onAnswered(
    MathRushAnswered event,
    Emitter<MathRushState> emit,
  ) async {
    if (state.status != MathRushStatus.playing) return;
    if (state.currentQuestion == null) return;

    final bool isCorrect =
        event.selectedAnswer == state.currentQuestion!.correctAnswer;

    if (isCorrect) {
      // Calculate score with time bonus
      final int basePoints = 10;
      final double timeRatio = state.timeRemaining / state.maxTime;
      final int timeBonus = (timeRatio * 10).round();
      final int totalPoints = basePoints + timeBonus;

      // Show correct feedback briefly
      emit(
        state.copyWith(
          status: MathRushStatus.correct,
          score: state.score + totalPoints,
        ),
      );

      // Wait a brief moment then move to next question
      await Future.delayed(const Duration(milliseconds: 300));

      final int nextLevel = state.level + 1;
      final double nextMaxTime = max(2.0, 5.0 - (nextLevel - 1) * 0.2);
      final question = _generateQuestion(nextLevel);

      emit(
        state.copyWith(
          status: MathRushStatus.playing,
          level: nextLevel,
          currentQuestion: question,
          timeRemaining: nextMaxTime,
          maxTime: nextMaxTime,
        ),
      );
    } else {
      // Wrong answer - game over
      final int nextHighScore = state.score > state.highScore
          ? state.score
          : state.highScore;
      if (nextHighScore != state.highScore) {
        _saveHighScore(nextHighScore);
      }

      emit(
        state.copyWith(status: MathRushStatus.wrong, highScore: nextHighScore),
      );

      // Brief pause to show wrong state before game over
      await Future.delayed(const Duration(milliseconds: 500));

      emit(state.copyWith(status: MathRushStatus.gameOver));
    }
  }

  MathQuestion _generateQuestion(int level) {
    late MathOperation operation;
    late int maxNumber;

    // Determine difficulty based on level
    if (level <= 5) {
      // Level 1-5: Simple addition and subtraction (0-10)
      operation = _random.nextBool()
          ? MathOperation.add
          : MathOperation.subtract;
      maxNumber = 10;
    } else if (level <= 10) {
      // Level 6-10: Addition and subtraction (0-20)
      operation = _random.nextBool()
          ? MathOperation.add
          : MathOperation.subtract;
      maxNumber = 20;
    } else if (level <= 15) {
      // Level 11-15: Multiplication (1-10)
      operation = MathOperation.multiply;
      maxNumber = 10;
    } else {
      // Level 16+: Mixed operations with larger numbers
      final ops = [
        MathOperation.add,
        MathOperation.subtract,
        MathOperation.multiply,
      ];
      operation = ops[_random.nextInt(3)];
      maxNumber = operation == MathOperation.multiply ? 12 : 30;
    }

    int operand1, operand2, correctAnswer;

    switch (operation) {
      case MathOperation.add:
        operand1 = _random.nextInt(maxNumber) + 1;
        operand2 = _random.nextInt(maxNumber) + 1;
        correctAnswer = operand1 + operand2;
        break;
      case MathOperation.subtract:
        // Ensure positive result
        operand1 = _random.nextInt(maxNumber) + maxNumber ~/ 2;
        operand2 = _random.nextInt(min(operand1, maxNumber)) + 1;
        correctAnswer = operand1 - operand2;
        break;
      case MathOperation.multiply:
        operand1 = _random.nextInt(maxNumber) + 1;
        operand2 = _random.nextInt(min(maxNumber, 10)) + 1;
        correctAnswer = operand1 * operand2;
        break;
    }

    // Randomly choose which position is missing
    final positions = [
      MissingPosition.first,
      MissingPosition.second,
      MissingPosition.result,
    ];
    final missingPosition = positions[_random.nextInt(3)];

    int answerToFind;
    switch (missingPosition) {
      case MissingPosition.first:
        answerToFind = operand1;
        break;
      case MissingPosition.second:
        answerToFind = operand2;
        break;
      case MissingPosition.result:
        answerToFind = correctAnswer;
        break;
    }

    // Generate 3 options (1 correct, 2 wrong but plausible)
    final List<int> options = [answerToFind];
    final Set<int> used = {answerToFind};

    while (options.length < 3) {
      // Generate plausible wrong answers
      int wrongAnswer;
      if (_random.nextBool()) {
        wrongAnswer = max(1, answerToFind + _random.nextInt(5) - 2);
      } else {
        wrongAnswer = max(1, answerToFind - _random.nextInt(3) + 1);
      }

      if (!used.contains(wrongAnswer) && wrongAnswer > 0) {
        options.add(wrongAnswer);
        used.add(wrongAnswer);
      }
    }

    // Shuffle options
    options.shuffle(_random);

    return MathQuestion(
      operand1: operand1,
      operand2: operand2,
      operation: operation,
      missingPosition: missingPosition,
      correctAnswer: answerToFind,
      options: options,
    );
  }

  Future<void> _saveHighScore(int score) async {
    await HighScoreStore.setHighScore('mathRush_highScore', score);
  }
}
