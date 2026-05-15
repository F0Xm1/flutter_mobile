import 'dart:developer';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test1/data/repositories/export_repository.dart';

class ExportService {
  final _repo = ExportRepository();

  Future<void> exportToCsv(
    String locationName,
    List<Map<String, dynamic>> sensors,
    DateTime from,
    DateTime to,
  ) async {
    final rows = <List<dynamic>>[
      ['Час', 'Тип', 'Значення', 'Одиниця'],
    ];

    for (final sensor in sensors) {
      final sensorId = sensor['id'] as String;
      final type = sensor['type'] as String;
      final unit = sensor['unit'] as String;
      final label = _labelFor(type);

      final records =
          await _repo.getTelemetryRange(sensorId, from: from, to: to);

      for (final r in records) {
        final raw = r['recorded_at'] as String;
        final dt = DateTime.parse(raw).toLocal();
        final formatted = _fmtDateTime(dt);
        final value = (r['value'] as num).toDouble();
        rows.add([formatted, label, value.toStringAsFixed(1), unit]);
      }
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();

    final dateStr = '${from.year}'
        '${from.month.toString().padLeft(2, '0')}'
        '${from.day.toString().padLeft(2, '0')}';
    final safeName = locationName.replaceAll(RegExp(r'[^\w]'), '_');
    final file = File('${dir.path}/chipidiezel_${safeName}_$dateStr.csv');
    await file.writeAsString(csv);

    log('Exporting CSV: ${file.path}', name: 'ExportService');
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Телеметрія: $locationName',
    );
  }

  String _labelFor(String type) => switch (type) {
        'temperature' => 'Температура',
        'humidity' => 'Вологість',
        _ => 'Тиск',
      };

  String _fmtDateTime(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';
}
