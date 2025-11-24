import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_application_1/data/models/workspace.dart';
import 'package:flutter_application_1/repositories/workspace_repository.dart';

part 'workspace_event.dart';
part 'workspace_state.dart';

class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  final WorkspaceRepository _repository;

  WorkspaceBloc(this._repository) : super(WorkspaceInitial()) {
    on<WorkspaceSubscriptionRequested>(_onSubscriptionRequested);
    on<WorkspaceCreateRequested>(_onCreateRequested);
  }

  Future<void> _onSubscriptionRequested(
    WorkspaceSubscriptionRequested event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(WorkspaceLoading());
    try {
      final workspaces =
          await _repository.fetchUserWorkspaces(event.userId);
      emit(WorkspaceLoaded(workspaces));
    } catch (e) {
      emit(WorkspaceError(e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    WorkspaceCreateRequested event,
    Emitter<WorkspaceState> emit,
  ) async {
    try {
      await _repository.createWorkspace(
        name: event.name,
        ownerId: event.ownerId,
      );

      final workspaces =
          await _repository.fetchUserWorkspaces(event.ownerId);
      emit(WorkspaceLoaded(workspaces));
    } catch (e) {
      emit(WorkspaceError(e.toString()));
    }
  }
}
