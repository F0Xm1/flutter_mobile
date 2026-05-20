import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test1/data/repositories/export_repository.dart';

class ExportService {
  final _repo = ExportRepository();

  Future<String> exportToXlsx(
    String locationName,
    List<Map<String, dynamic>> sensors,
    DateTime from,
    DateTime to,
  ) async {
    final workbook = Excel.createExcel();
    if (workbook.sheets.containsKey('Sheet1')) {
      workbook.rename('Sheet1', 'Телеметрія');
    }
    final sheet = workbook['Телеметрія'];

    sheet.appendRow([
      TextCellValue('Час'),
      TextCellValue('Сенсор'),
      TextCellValue('Тип'),
      TextCellValue('Значення'),
      TextCellValue('Одиниця'),
    ]);

    for (final sensor in sensors) {
      final sensorId = sensor['id'] as String;
      final sensorName = sensor['name'] as String;
      final type = sensor['type'] as String;
      final unit = sensor['unit'] as String;
      final label = _labelFor(type);

      final records =
          await _repo.getTelemetryRange(sensorId, from: from, to: to);

      for (final r in records) {
        final raw = r['recorded_at'] as String;
        final dt = DateTime.parse(raw).toLocal();
        final value = (r['value'] as num).toDouble();
        sheet.appendRow([
          TextCellValue(_fmtDateTime(dt)),
          TextCellValue(sensorName),
          TextCellValue(label),
          DoubleCellValue(value),
          TextCellValue(unit),
        ]);
      }
    }

    final bytes = workbook.encode();
    if (bytes == null) throw Exception('Не вдалося створити файл');

    final dateStr = '${from.year}'
        '${from.month.toString().padLeft(2, '0')}'
        '${from.day.toString().padLeft(2, '0')}';
    final safeName = locationName.replaceAll(RegExp(r'[^\w]'), '_');
    final filename = 'chipidiezel_${safeName}_$dateStr.xlsx';

    final file = File('${await _downloadsPath()}/$filename');
    await file.writeAsBytes(bytes);

    log('Exported to: ${file.path}', name: 'ExportService');
    return filename;
  }

  Future<String> _downloadsPath() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (dir.existsSync()) return dir.path;
    }
    final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    return dir.path;
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
