import 'package:equatable/equatable.dart';

abstract class NeonBlasterEvent extends Equatable {
  const NeonBlasterEvent();

  @override
  List<Object> get props => [];
}

class NeonBlasterStarted extends NeonBlasterEvent {
  final int bonusScore;

  const NeonBlasterStarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class NeonBlasterTicked extends NeonBlasterEvent {
  final double deltaTime;

  const NeonBlasterTicked(this.deltaTime);

  @override
  List<Object> get props => [deltaTime];
}

class NeonBlasterPlayerMoved extends NeonBlasterEvent {
  final double normalizedX;

  const NeonBlasterPlayerMoved(this.normalizedX);

  @override
  List<Object> get props => [normalizedX];
}

class NeonBlasterRestarted extends NeonBlasterEvent {
  final int bonusScore;

  const NeonBlasterRestarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}
