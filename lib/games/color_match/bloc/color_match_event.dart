import 'package:equatable/equatable.dart';

abstract class ColorMatchEvent extends Equatable {
  const ColorMatchEvent();

  @override
  List<Object> get props => [];
}

class ColorMatchStarted extends ColorMatchEvent {
  final int bonusScore;

  const ColorMatchStarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class ColorMatchTicked extends ColorMatchEvent {
  final double deltaTime;
  const ColorMatchTicked(this.deltaTime);

  @override
  List<Object> get props => [deltaTime];
}

class ColorMatchRotated extends ColorMatchEvent {}

class ColorMatchRestarted extends ColorMatchEvent {
  final int bonusScore;

  const ColorMatchRestarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}
