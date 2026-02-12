import 'package:equatable/equatable.dart';

abstract class BallSortEvent extends Equatable {
  const BallSortEvent();

  @override
  List<Object?> get props => [];
}

class BallSortStarted extends BallSortEvent {
  const BallSortStarted();
}

class BallSortTubeTapped extends BallSortEvent {
  final int tubeIndex;

  const BallSortTubeTapped(this.tubeIndex);

  @override
  List<Object?> get props => [tubeIndex];
}

class BallSortRestarted extends BallSortEvent {
  const BallSortRestarted();
}

class BallSortUndo extends BallSortEvent {
  const BallSortUndo();
}

class BallSortNextLevel extends BallSortEvent {
  const BallSortNextLevel();
}

class BallSortRevived extends BallSortEvent {
  const BallSortRevived();
}
