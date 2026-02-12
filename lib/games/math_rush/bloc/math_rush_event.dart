import 'package:equatable/equatable.dart';

abstract class MathRushEvent extends Equatable {
  const MathRushEvent();

  @override
  List<Object> get props => [];
}

class MathRushStarted extends MathRushEvent {
  final int bonusScore;

  const MathRushStarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class MathRushTicked extends MathRushEvent {
  final double deltaTime;
  const MathRushTicked(this.deltaTime);

  @override
  List<Object> get props => [deltaTime];
}

class MathRushAnswered extends MathRushEvent {
  final int selectedAnswer;

  const MathRushAnswered(this.selectedAnswer);

  @override
  List<Object> get props => [selectedAnswer];
}

class MathRushRestarted extends MathRushEvent {
  final int bonusScore;

  const MathRushRestarted({this.bonusScore = 0});

  @override
  List<Object> get props => [bonusScore];
}

class MathRushRevived extends MathRushEvent {}
