import 'package:equatable/equatable.dart';

abstract class NumberMergeEvent extends Equatable {
  const NumberMergeEvent();

  @override
  List<Object?> get props => [];
}

class NumberMergeStarted extends NumberMergeEvent {
  const NumberMergeStarted();
}

class NumberMergeColumnTapped extends NumberMergeEvent {
  final int columnIndex;

  const NumberMergeColumnTapped(this.columnIndex);

  @override
  List<Object?> get props => [columnIndex];
}

class NumberMergeRestarted extends NumberMergeEvent {
  const NumberMergeRestarted();
}

class NumberMergeRevived extends NumberMergeEvent {}
