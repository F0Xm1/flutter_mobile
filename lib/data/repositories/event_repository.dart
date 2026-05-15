import 'dart:async';
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test1/core/supabase_client.dart';

class EventRepository {
  Future<List<Map<String, dynamic>>> getEvents({int limit = 50}) async {
    try {
      final response = await supabase
          .from('events')
          .select()
          .order('triggered_at', ascending: false)
          .limit(limit);
      return response.map(Map<String, dynamic>.from).toList();
    } catch (error, stackTrace) {
      log(
        'Failed to fetch events',
        name: 'EventRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> watchEvents() {
    late final RealtimeChannel channel;
    final controller = StreamController<Map<String, dynamic>>();

    controller.onListen = () {
      try {
        channel = supabase.channel('events:inserts');
        channel
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'events',
              callback: (payload) {
                final record = payload.newRecord;
                if (record.isNotEmpty) {
                  controller.add(Map<String, dynamic>.from(record));
                }
              },
            )
            .subscribe((status, error) {
              log(
                'Events realtime status: $status',
                name: 'EventRepository',
                error: error,
              );
              if (error != null) controller.addError(error);
            });
      } catch (error, stackTrace) {
        log(
          'Failed to subscribe to events',
          name: 'EventRepository',
          error: error,
          stackTrace: stackTrace,
        );
        controller.addError(error, stackTrace);
      }
    };

    controller.onCancel = () async {
      try {
        await supabase.removeChannel(channel);
      } catch (error, stackTrace) {
        log(
          'Failed to unsubscribe from events',
          name: 'EventRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    };

    return controller.stream;
  }
}
