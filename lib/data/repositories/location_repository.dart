import 'dart:developer';

import 'package:test1/core/supabase_client.dart';

class LocationRepository {
  Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      final response = await supabase
          .from('locations')
          .select()
          .order('created_at', ascending: false);

      return response.map(Map<String, dynamic>.from).toList();
    } catch (error, stackTrace) {
      log(
        'Failed to fetch locations',
        name: 'LocationRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> createLocation(String name, String address) async {
    try {
      await supabase.from('locations').insert({
        'name': name,
        'address': address,
      });
    } catch (error, stackTrace) {
      log(
        'Failed to create location',
        name: 'LocationRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await supabase.from('locations').delete().eq('id', id);
    } catch (error, stackTrace) {
      log(
        'Failed to delete location',
        name: 'LocationRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
