import 'dart:developer';

import 'package:test1/core/supabase_client.dart';

class ExportRepository {
  Future<List<Map<String, dynamic>>> getTelemetryRange(
    String sensorId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await supabase
          .from('telemetry')
          .select()
          .eq('sensor_id', sensorId)
          .gte('recorded_at', from.toUtc().toIso8601String())
          .lte('recorded_at', to.toUtc().toIso8601String())
          .order('recorded_at', ascending: true);

      return response.map(Map<String, dynamic>.from).toList();
    } catch (error, stackTrace) {
      log(
        'Failed to fetch telemetry range',
        name: 'ExportRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
