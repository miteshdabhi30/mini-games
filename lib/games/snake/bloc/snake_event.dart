import 'package:equatable/equatable.dart';

abstract class SnakeEvent extends Equatable {
  const SnakeEvent();

  @override
  List<Object> get props => [];
}

class SnakeStarted extends SnakeEvent {
  final int bonusScore;

  const SnakeStarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class SnakeTicked extends SnakeEvent {
  final double deltaTime;
  const SnakeTicked(this.deltaTime);

  @override
  List<Object> get props => [deltaTime];
}

class SnakeDirectionChanged extends SnakeEvent {
  final int dx;
  final int dy;
  const SnakeDirectionChanged(this.dx, this.dy);

  @override
  List<Object> get props => [dx, dy];
}

class SnakeRestarted extends SnakeEvent {
  final int bonusScore;

  const SnakeRestarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}
