import 'package:equatable/equatable.dart';

abstract class NeonLoopEvent extends Equatable {
  const NeonLoopEvent();

  @override
  List<Object?> get props => [];
}

class NeonLoopStarted extends NeonLoopEvent {
  const NeonLoopStarted();
}

class NeonLoopTicked extends NeonLoopEvent {
  final double deltaTime;
  const NeonLoopTicked(this.deltaTime);

  @override
  List<Object?> get props => [deltaTime];
}

class NeonLoopTapped extends NeonLoopEvent {
  const NeonLoopTapped();
}

class NeonLoopRestarted extends NeonLoopEvent {
  final int bonusScore;
  const NeonLoopRestarted({this.bonusScore = 0});

  @override
  List<Object?> get props => [bonusScore];
}
