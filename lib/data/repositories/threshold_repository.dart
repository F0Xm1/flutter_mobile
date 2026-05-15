import 'dart:developer';

import 'package:test1/core/supabase_client.dart';

class ThresholdRepository {
  Future<Map<String, dynamic>?> getThreshold(String sensorId) async {
    try {
      final response = await supabase
          .from('thresholds')
          .select()
          .eq('sensor_id', sensorId)
          .maybeSingle();
      return response;
    } catch (error, stackTrace) {
      log(
        'Failed to fetch threshold',
        name: 'ThresholdRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> upsertThreshold(
    String sensorId,
    double? min,
    double? max,
  ) async {
    try {
      await supabase.from('thresholds').upsert(
        {
          'sensor_id': sensorId,
          'min_value': min,
          'max_value': max,
        },
        onConflict: 'sensor_id',
      );
    } catch (error, stackTrace) {
      log(
        'Failed to upsert threshold',
        name: 'ThresholdRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
