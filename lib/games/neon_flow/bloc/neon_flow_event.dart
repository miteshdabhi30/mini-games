import 'package:equatable/equatable.dart';

abstract class NeonFlowEvent extends Equatable {
  const NeonFlowEvent();

  @override
  List<Object?> get props => [];
}

class NeonFlowLevelStarted extends NeonFlowEvent {
  const NeonFlowLevelStarted();
}

class NeonFlowNextLevel extends NeonFlowEvent {
  const NeonFlowNextLevel();
}

class NeonFlowDragStarted extends NeonFlowEvent {
  final int row;
  final int col;
  const NeonFlowDragStarted(this.row, this.col);

  @override
  List<Object?> get props => [row, col];
}

class NeonFlowDragUpdated extends NeonFlowEvent {
  final int row;
  final int col;
  const NeonFlowDragUpdated(this.row, this.col);

  @override
  List<Object?> get props => [row, col];
}

class NeonFlowDragEnded extends NeonFlowEvent {
  const NeonFlowDragEnded();
}

class NeonFlowRevived extends NeonFlowEvent {
  const NeonFlowRevived();
}

class NeonFlowHint extends NeonFlowEvent {
  const NeonFlowHint();
}
