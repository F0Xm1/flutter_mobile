import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test1/src/domain/models/sensor.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.1.133:5001';

  static Future<List<Sensor>> fetchSensors() async {
    final response = await http.get(Uri.parse('$baseUrl/sensors'));

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => Sensor.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Невірний формат відповіді (очікувався List)');
      }
    } else {
      throw Exception('Не вдалося завантажити сенсори');
    }
  }

  static Future<Sensor> createSensor(Sensor sensor) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sensors'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sensor.toJson()),
    );

    if (response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('id')) {
        return sensor.copyWith(id: decoded['id'] as int);
      } else {
        throw Exception('Невірна відповідь від сервера');
      }
    } else {
      throw Exception('Помилка створення сенсора');
    }
  }

  static Future<void> updateSensor(Sensor sensor) async {
    await http.put(
      Uri.parse('$baseUrl/sensors/${sensor.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(sensor.toJson()),
    );
  }

  static Future<void> deleteSensor(int id) async {
    await http.delete(Uri.parse('$baseUrl/sensors/$id'));
  }
}
