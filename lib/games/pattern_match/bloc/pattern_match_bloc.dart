import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_object/utils/high_score_store.dart';
import 'pattern_match_event.dart';
import 'pattern_match_state.dart';

class PatternMatchBloc extends Bloc<PatternMatchEvent, PatternMatchState> {
  final Random _random = Random();

  PatternMatchBloc() : super(const PatternMatchState()) {
    on<PatternMatchStarted>(_onStarted);
    on<PatternMatchRestarted>(_onRestarted);
    on<PatternMatchShowPattern>(_onShowPattern);
    on<PatternMatchButtonTapped>(_onButtonTapped);
    on<PatternMatchNextRound>(_onNextRound);
    on<PatternMatchRevived>(_onRevived);
  }

  Future<void> _onRevived(
    PatternMatchRevived event,
    Emitter<PatternMatchState> emit,
  ) async {
    if (state.status != PatternMatchStatus.gameOver || state.reviveUsed) return;

    // Revive Logic: Replay current pattern
    emit(
      state.copyWith(
        status: PatternMatchStatus.idle, // Brief idle before show
        playerInput: [],
        highlightedButton: null,
        reviveUsed: true,
      ),
    );

    // Trigger show pattern
    await Future.delayed(const Duration(milliseconds: 500));
    if (!isClosed) {
      add(const PatternMatchShowPattern());
    }
  }

  Future<void> _onStarted(
    PatternMatchStarted event,
    Emitter<PatternMatchState> emit,
  ) async {
    final highScore = HighScoreStore.getHighScore('patternMatch_highScore');
    emit(
      state.copyWith(
        status: PatternMatchStatus.idle,
        highScore: highScore,
        score: 0,
        currentRound: 1,
        pattern: [],
        playerInput: [],
      ),
    );
    // Start first round
    add(const PatternMatchNextRound());
  }

  Future<void> _onRestarted(
    PatternMatchRestarted event,
    Emitter<PatternMatchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PatternMatchStatus.idle,
        score: event.bonusScore,
        currentRound: 1,
        pattern: [],
        playerInput: [],
        highlightedButton: null,
      ),
    );
    // Start first round
    add(const PatternMatchNextRound());
  }

  Future<void> _onNextRound(
    PatternMatchNextRound event,
    Emitter<PatternMatchState> emit,
  ) async {
    // Generate new pattern (add one more step)
    final newPattern = List<int>.from(state.pattern);
    newPattern.add(_random.nextInt(4)); // 0-3 for 4 buttons

    emit(
      state.copyWith(
        pattern: newPattern,
        playerInput: [],
        currentRound: newPattern.length,
        status: PatternMatchStatus.idle,
        highlightedButton: null,
      ),
    );

    // Show the pattern after a brief delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (!isClosed) {
      add(const PatternMatchShowPattern());
    }
  }

  Future<void> _onShowPattern(
    PatternMatchShowPattern event,
    Emitter<PatternMatchState> emit,
  ) async {
    emit(state.copyWith(status: PatternMatchStatus.showingPattern));

    // Show each button in the pattern with delays
    for (int i = 0; i < state.pattern.length; i++) {
      if (isClosed) return;

      final buttonIndex = state.pattern[i];

      // Highlight button
      emit(state.copyWith(highlightedButton: buttonIndex));
      await Future.delayed(const Duration(milliseconds: 400));

      if (isClosed) return;

      // Turn off highlight
      emit(state.copyWith(highlightedButton: null));
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (isClosed) return;

    // Pattern shown, now player's turn
    emit(
      state.copyWith(
        status: PatternMatchStatus.playerTurn,
        highlightedButton: null,
      ),
    );
  }

  Future<void> _onButtonTapped(
    PatternMatchButtonTapped event,
    Emitter<PatternMatchState> emit,
  ) async {
    if (state.status != PatternMatchStatus.playerTurn) return;

    final currentInputIndex = state.playerInput.length;
    final expectedButton = state.pattern[currentInputIndex];

    // Add to player input
    final newPlayerInput = List<int>.from(state.playerInput);
    newPlayerInput.add(event.buttonIndex);

    // Visual feedback - highlight the button
    emit(state.copyWith(highlightedButton: event.buttonIndex));
    await Future.delayed(const Duration(milliseconds: 200));

    if (isClosed) return;

    emit(state.copyWith(highlightedButton: null));

    // Check if correct
    if (event.buttonIndex != expectedButton) {
      // Wrong! Game over
      final nextHighScore = state.score > state.highScore
          ? state.score
          : state.highScore;
      if (nextHighScore != state.highScore) {
        await _saveHighScore(nextHighScore);
      }

      emit(
        state.copyWith(
          status: PatternMatchStatus.gameOver,
          playerInput: newPlayerInput,
          highScore: nextHighScore,
        ),
      );
      return;
    }

    // Correct so far
    emit(state.copyWith(playerInput: newPlayerInput));

    // Check if pattern completed
    if (newPlayerInput.length == state.pattern.length) {
      // Round complete! Add score and go to next round
      final newScore = state.score + 10;
      emit(state.copyWith(score: newScore));

      await Future.delayed(const Duration(milliseconds: 500));

      if (!isClosed) {
        add(const PatternMatchNextRound());
      }
    }
  }

  Future<void> _saveHighScore(int score) async {
    await HighScoreStore.setHighScore('patternMatch_highScore', score);
  }
}
