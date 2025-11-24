part of 'todo_bloc.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class TodoSubscriptionRequested extends TodoEvent {
  final String workspaceId;

  const TodoSubscriptionRequested(this.workspaceId);

  @override
  List<Object?> get props => [workspaceId];
}

class TodoAddRequested extends TodoEvent {
  final String workspaceId;
  final String title;

  const TodoAddRequested({
    required this.workspaceId,
    required this.title,
  });

  @override
  List<Object?> get props => [workspaceId, title];
}

class TodoToggleRequested extends TodoEvent {
  final TodoItem item;

  const TodoToggleRequested(this.item);

  @override
  List<Object?> get props => [item];
}

class TodoDeleteRequested extends TodoEvent {
  final String id;

  const TodoDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class TodoRenameRequested extends TodoEvent {
  final String id;
  final String title;

  const TodoRenameRequested({
    required this.id,
    required this.title,
  });

  @override
  List<Object?> get props => [id, title];
}

class _TodoUpdated extends TodoEvent {
  final List<TodoItem> todos;

  const _TodoUpdated(this.todos);

  @override
  List<Object?> get props => [todos];
}
