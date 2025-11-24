part of 'activity_bloc.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

class ActivitySubscriptionRequested extends ActivityEvent {
  final String workspaceId;

  const ActivitySubscriptionRequested(this.workspaceId);

  @override
  List<Object?> get props => [workspaceId];
}

class _ActivityUpdated extends ActivityEvent {
  final List<ActivityLog> logs;

  const _ActivityUpdated(this.logs);

  @override
  List<Object?> get props => [logs];
}
