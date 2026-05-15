import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _prefix = 'cache_location_';

  Future<void> saveLastValues(
    String locationId,
    Map<String, dynamic> values,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$locationId', jsonEncode(values));
    } catch (error, stackTrace) {
      log(
        'Failed to save cache for $locationId',
        name: 'CacheService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>?> getLastValues(String locationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$locationId');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      log(
        'Failed to read cache for $locationId',
        name: 'CacheService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (error, stackTrace) {
      log(
        'Failed to clear cache',
        name: 'CacheService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
