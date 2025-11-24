import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_application_1/data/models/activity_log.dart';
import 'package:flutter_application_1/repositories/activity_repository.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _repository;
  StreamSubscription<List<ActivityLog>>? _subscription;

  ActivityBloc(this._repository) : super(ActivityLoading()) {
    on<ActivitySubscriptionRequested>(_onSubscriptionRequested);
    on<_ActivityUpdated>(_onUpdated);
  }

  void _onSubscriptionRequested(
    ActivitySubscriptionRequested event,
    Emitter<ActivityState> emit,
  ) {
    emit(ActivityLoading());

    _subscription?.cancel();
    _subscription = _repository.watchActivity(event.workspaceId).listen(
      (logs) {
        add(_ActivityUpdated(logs));
      },
      onError: (error) {
        emit(ActivityError(error.toString()));
      },
    );
  }

  void _onUpdated(
    _ActivityUpdated event,
    Emitter<ActivityState> emit,
  ) {
    emit(ActivityLoaded(event.logs));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
