import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_application_1/data/models/todo_item.dart';
import 'package:flutter_application_1/repositories/todo_repository.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;
  StreamSubscription<List<TodoItem>>? _subscription;

  // ✅ Remember deleted IDs so they never show again in this session
  final Set<String> _deletedIds = {};

  TodoBloc(this._repository) : super(TodoLoading()) {
    on<TodoSubscriptionRequested>(_onSubscriptionRequested);
    on<_TodoUpdated>(_onUpdated);
    on<TodoAddRequested>(_onAddRequested);
    on<TodoToggleRequested>(_onToggleRequested);
    on<TodoDeleteRequested>(_onDeleteRequested);
    on<TodoRenameRequested>(_onRenameRequested);
  }

  void _onSubscriptionRequested(
    TodoSubscriptionRequested event,
    Emitter<TodoState> emit,
  ) {
    emit(TodoLoading());
    _subscription?.cancel();

    _subscription = _repository.watchTodos(event.workspaceId).listen(
      (todos) {
        // 🔥 Filter out any deleted IDs before updating state
        final filtered = todos
            .where((t) => !_deletedIds.contains(t.id))
            .toList();

        add(_TodoUpdated(filtered));
      },
      onError: (error) {
        emit(TodoError(error.toString()));
      },
    );
  }

  void _onUpdated(
    _TodoUpdated event,
    Emitter<TodoState> emit,
  ) {
    emit(TodoLoaded(event.todos));
  }

  Future<void> _onAddRequested(
    TodoAddRequested event,
    Emitter<TodoState> emit,
  ) async {
    await _repository.addTodo(event.workspaceId, event.title);
    // Stream will send new list; filter will still apply
  }

  Future<void> _onToggleRequested(
    TodoToggleRequested event,
    Emitter<TodoState> emit,
  ) async {
    // ✅ Optimistic toggle
    final current = state;
    if (current is TodoLoaded) {
      final updated = current.todos.map((t) {
        if (t.id == event.item.id) {
          return TodoItem(
            id: t.id,
            workspaceId: t.workspaceId,
            title: t.title,
            completed: !t.completed,
            createdAt: t.createdAt,
          );
        }
        return t;
      }).toList();

      emit(TodoLoaded(updated));
    }

    await _repository.toggleTodo(event.item);
  }

  Future<void> _onDeleteRequested(
    TodoDeleteRequested event,
    Emitter<TodoState> emit,
  ) async {
    // ✅ Remember that this ID is deleted in this session
    _deletedIds.add(event.id);

    // ✅ Optimistic delete from current list
    final current = state;
    if (current is TodoLoaded) {
      final updated =
          current.todos.where((t) => t.id != event.id).toList();
      emit(TodoLoaded(updated));
    }

    await _repository.deleteTodo(event.id);
  }

  Future<void> _onRenameRequested(
    TodoRenameRequested event,
    Emitter<TodoState> emit,
  ) async {
    // ✅ Optimistic rename
    final current = state;
    if (current is TodoLoaded) {
      final updated = current.todos.map((t) {
        if (t.id == event.id) {
          return TodoItem(
            id: t.id,
            workspaceId: t.workspaceId,
            title: event.title,
            completed: t.completed,
            createdAt: t.createdAt,
          );
        }
        return t;
      }).toList();

      emit(TodoLoaded(updated));
    }

    await _repository.renameTodo(event.id, event.title);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
