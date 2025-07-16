import 'package:flutter/material.dart';
import 'package:test1/src/domain/models/sensor.dart';

class SensorEditorPage {
  static const darkBackground = Color(0xFF1A1B2D);
  static const accentPurple = Color(0xFF8A2BE2);
  static const lightPurple = Color(0xFFB19CD9);

  static Future<Sensor?> show(BuildContext context, {Sensor? sensor}) {
    return showDialog<Sensor>(
      context: context,
      builder: (context) => _SensorDialog(sensor: sensor),
    );
  }
}

class _SensorDialog extends StatefulWidget {
  final Sensor? sensor;

  const _SensorDialog({super.key, this.sensor});

  @override
  State<_SensorDialog> createState() => _SensorDialogState();
}

class _SensorDialogState extends State<_SensorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sensor?.name ?? '');
    _typeController = TextEditingController(text: widget.sensor?.type ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.sensor != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: SensorEditorPage.darkBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Редагування сенсора' : 'Новий сенсор',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Назва'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _typeController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Тип'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Скасувати',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SensorEditorPage.accentPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final type = _typeController.text.trim();

                    if (name.isNotEmpty && type.isNotEmpty) {
                      final sensor = Sensor(
                        id: widget.sensor?.id ??
                            DateTime.now().millisecondsSinceEpoch,
                        name: name,
                        type: type,
                      );
                      Navigator.pop(context, sensor);
                    }
                  },
                  child: Text(
                    isEdit ? 'Зберегти' : 'Створити',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: SensorEditorPage.accentPurple),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
