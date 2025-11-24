part of 'workspace_bloc.dart';

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class WorkspaceSubscriptionRequested extends WorkspaceEvent {
  final String userId;

  const WorkspaceSubscriptionRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class WorkspaceCreateRequested extends WorkspaceEvent {
  final String name;
  final String ownerId;

  const WorkspaceCreateRequested(this.name, this.ownerId);

  @override
  List<Object?> get props => [name, ownerId];
}
