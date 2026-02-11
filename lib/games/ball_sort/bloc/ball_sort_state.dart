import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum BallSortStatus { initial, playing, levelCompleted }

class BallSortState extends Equatable {
  final BallSortStatus status;
  final List<List<Color>> tubes;
  final int? selectedTubeIndex;
  final int level;
  final int moves;
  final List<List<List<Color>>> history; // For undo

  const BallSortState({
    this.status = BallSortStatus.initial,
    this.tubes = const [],
    this.selectedTubeIndex,
    this.level = 1,
    this.moves = 0,
    this.history = const [],
  });

  BallSortState copyWith({
    BallSortStatus? status,
    List<List<Color>>? tubes,
    int? selectedTubeIndex,
    int? level,
    int? moves,
    List<List<List<Color>>>? history,
  }) {
    return BallSortState(
      status: status ?? this.status,
      tubes: tubes ?? this.tubes,
      selectedTubeIndex: selectedTubeIndex, // Intentionally nullable
      level: level ?? this.level,
      moves: moves ?? this.moves,
      history: history ?? this.history,
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
    );
  }

  @override
  List<Object?> get props => [
    status,
    tubes,
    selectedTubeIndex,
    level,
    moves,
    history, // history equality might be expensive but okay for now
  ];
}
