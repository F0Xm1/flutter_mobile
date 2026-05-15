import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/data/repositories/event_repository.dart';

part 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  EventsCubit() : super(const EventsInitial());

  final _repo = EventRepository();
  StreamSubscription<Map<String, dynamic>>? _subscription;

  Future<void> loadAndWatch() async {
    emit(const EventsLoading());
    try {
      final events = await _repo.getEvents();
      emit(EventsLoaded(events));

      _subscription = _repo.watchEvents().listen(
        (newEvent) {
          final current = state;
          if (current is EventsLoaded) {
            emit(EventsLoaded([newEvent, ...current.events]));
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          log(
            'Events stream error',
            name: 'EventsCubit',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (error, stackTrace) {
      log(
        'Failed to load events',
        name: 'EventsCubit',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const EventsError('Не вдалося завантажити журнал подій'));
    }
  }

  Future<void> refresh() async {
    try {
      final events = await _repo.getEvents();
      emit(EventsLoaded(events));
    } catch (error, stackTrace) {
      log(
        'Failed to refresh events',
        name: 'EventsCubit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
