import 'package:equatable/equatable.dart';

abstract class NeonBridgeEvent extends Equatable {
  const NeonBridgeEvent();

  @override
  List<Object> get props => [];
}

class GameStarted extends NeonBridgeEvent {
  final int bonusScore;

  const GameStarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class StartGrow extends NeonBridgeEvent {}

class StopGrow extends NeonBridgeEvent {}

class GameTick extends NeonBridgeEvent {}

class GameReset extends NeonBridgeEvent {
  final int bonusScore;

  const GameReset({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class AnimationCompleted extends NeonBridgeEvent {}
