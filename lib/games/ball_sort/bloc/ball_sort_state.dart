import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum BallSortStatus { initial, playing, levelCompleted, gameOver }

class BallSortState extends Equatable {
  final BallSortStatus status;
  final List<List<Color>> tubes;
  final int? selectedTubeIndex;
  final int level;
  final int moves;
  final List<List<List<Color>>> history; // For undo
  final bool reviveUsed;

  const BallSortState({
    this.status = BallSortStatus.initial,
    this.tubes = const [],
    this.selectedTubeIndex,
    this.level = 1,
    this.moves = 0,
    this.history = const [],
    this.reviveUsed = false,
  });

  BallSortState copyWith({
    BallSortStatus? status,
    List<List<Color>>? tubes,
    int? selectedTubeIndex,
    int? level,
    int? moves,
    List<List<List<Color>>>? history,
    bool? reviveUsed,
  }) {
    return BallSortState(
      status: status ?? this.status,
      tubes: tubes ?? this.tubes,
      selectedTubeIndex: selectedTubeIndex, // Intentionally nullable
      level: level ?? this.level,
      moves: moves ?? this.moves,
      history: history ?? this.history,
      reviveUsed: reviveUsed ?? this.reviveUsed,
    );
  }

  // Helper to clear selection
  BallSortState clearSelection() {
    return BallSortState(
      status: status,
      tubes: tubes,
      selectedTubeIndex: null,
      level: level,
      moves: moves,
      history: history,
      reviveUsed: reviveUsed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tubes,
    selectedTubeIndex,
    level,
    moves,
    history,
    reviveUsed,
  ];
}
