import 'package:equatable/equatable.dart';

abstract class TowerStackEvent extends Equatable {
  const TowerStackEvent();

  @override
  List<Object> get props => [];
}

class TowerStackStarted extends TowerStackEvent {
  final int bonusScore;

  const TowerStackStarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class TowerStackTicked extends TowerStackEvent {
  final double deltaTime;
  const TowerStackTicked(this.deltaTime);

  @override
  List<Object> get props => [deltaTime];
}

class TowerStackTapped extends TowerStackEvent {}

class TowerStackRestarted extends TowerStackEvent {
  final int bonusScore;

  const TowerStackRestarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class TowerStackRevived extends TowerStackEvent {}
