import 'package:equatable/equatable.dart';

abstract class NeonHitEvent extends Equatable {
  const NeonHitEvent();

  @override
  List<Object> get props => [];
}

class GameStarted extends NeonHitEvent {
  final int bonusScore;

  const GameStarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class ThrowSpike extends NeonHitEvent {}

class GameTick extends NeonHitEvent {}

class GameReset extends NeonHitEvent {
  final int bonusScore;

  const GameReset({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}
