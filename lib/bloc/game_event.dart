part of 'game_bloc.dart';


abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class GameStarted extends GameEvent {}

class GameTicked extends GameEvent {
  final double deltaTime;

  const GameTicked(this.deltaTime);

  @override
  List<Object> get props => [deltaTime];
}

class PlayerMoved extends GameEvent {
  final int laneIndex;

  const PlayerMoved(this.laneIndex);

  @override
  List<Object> get props => [laneIndex];
}

class GameRestarted extends GameEvent {
  final int bonusScore;

  const GameRestarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class GameRevived extends GameEvent {}
