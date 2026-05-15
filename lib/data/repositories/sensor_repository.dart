import 'dart:developer';

import 'package:test1/core/supabase_client.dart';

class SensorRepository {
  Future<List<Map<String, dynamic>>> getSensorsByLocation(
    String locationId,
  ) async {
    try {
      final response = await supabase
          .from('sensors')
          .select()
          .eq('location_id', locationId)
          .order('created_at', ascending: false);

      return response.map(Map<String, dynamic>.from).toList();
    } catch (error, stackTrace) {
      log(
        'Failed to fetch sensors by location',
        name: 'SensorRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSensors() async {
    try {
      final response = await supabase
          .from('sensors')
          .select()
          .order('created_at', ascending: false);

      return response.map(Map<String, dynamic>.from).toList();
    } catch (error, stackTrace) {
      log(
        'Failed to fetch all sensors',
        name: 'SensorRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> createSensor(
    String locationId,
    String name,
    String type,
    String unit,
  ) async {
    try {
      await supabase.from('sensors').insert({
        'location_id': locationId,
        'name': name,
        'type': type,
        'unit': unit,
      });
    } catch (error, stackTrace) {
      log(
        'Failed to create sensor',
        name: 'SensorRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteSensor(String id) async {
    try {
      await supabase.from('sensors').delete().eq('id', id);
    } catch (error, stackTrace) {
      log(
        'Failed to delete sensor',
        name: 'SensorRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
