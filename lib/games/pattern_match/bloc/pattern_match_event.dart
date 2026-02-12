import 'package:equatable/equatable.dart';

abstract class PatternMatchEvent extends Equatable {
  const PatternMatchEvent();

  @override
  List<Object?> get props => [];
}

class PatternMatchStarted extends PatternMatchEvent {
  const PatternMatchStarted();
}

class PatternMatchRestarted extends PatternMatchEvent {
  final int bonusScore;

  const PatternMatchRestarted({this.bonusScore = 0});

  @override
  List<Object?> get props => [bonusScore];
}

class PatternMatchShowPattern extends PatternMatchEvent {
  const PatternMatchShowPattern();
}

class PatternMatchButtonTapped extends PatternMatchEvent {
  final int buttonIndex;

  const PatternMatchButtonTapped(this.buttonIndex);

  @override
  List<Object?> get props => [buttonIndex];
}

class PatternMatchNextRound extends PatternMatchEvent {
  const PatternMatchNextRound();
}

class PatternMatchRevived extends PatternMatchEvent {
  const PatternMatchRevived();
}
