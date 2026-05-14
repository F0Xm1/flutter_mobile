import 'dart:async';
import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test1/core/supabase_client.dart';

class TelemetryRepository {
  Future<List<Map<String, dynamic>>> getLastTelemetry(
    String sensorId, {
    int limit = 50,
  }) async {
    try {
      final response = await supabase
          .from('telemetry')
          .select()
          .eq('sensor_id', sensorId)
          .order('recorded_at', ascending: false)
          .limit(limit);

      return response.map(Map<String, dynamic>.from).toList();
    } catch (error, stackTrace) {
      log(
        'Failed to fetch last telemetry',
        name: 'TelemetryRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> watchTelemetry(String sensorId) {
    late final RealtimeChannel channel;
    final controller = StreamController<Map<String, dynamic>>();

    controller.onListen = () {
      try {
        channel = supabase.channel('telemetry:sensor_id=eq.$sensorId');
        channel
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'telemetry',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'sensor_id',
                value: sensorId,
              ),
              callback: (payload) {
                final record = payload.newRecord;
                if (record.isNotEmpty) {
                  controller.add(Map<String, dynamic>.from(record));
                }
              },
            )
            .subscribe();
      } catch (error, stackTrace) {
        log(
          'Failed to subscribe to telemetry',
          name: 'TelemetryRepository',
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
          'Failed to unsubscribe from telemetry',
          name: 'TelemetryRepository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    };

    return controller.stream;
  }
}
