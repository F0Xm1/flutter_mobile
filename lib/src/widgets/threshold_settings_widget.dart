import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/src/cubit/threshold/threshold_cubit.dart';

class ThresholdSettingsWidget extends StatefulWidget {
  final String sensorId;
  final String label;
  final String unit;
  final ThresholdCubit cubit;
  final void Function(double? min, double? max) onSaved;

  const ThresholdSettingsWidget({
    required this.sensorId,
    required this.label,
    required this.unit,
    required this.cubit,
    required this.onSaved,
    super.key,
  });

  @override
  State<ThresholdSettingsWidget> createState() =>
      _ThresholdSettingsWidgetState();
}

class _ThresholdSettingsWidgetState extends State<ThresholdSettingsWidget> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    final loaded = widget.cubit.state is ThresholdLoaded
        ? widget.cubit.state as ThresholdLoaded
        : null;
    _minController = TextEditingController(
      text: loaded?.min?.toStringAsFixed(1) ?? '',
    );
    _maxController = TextEditingController(
      text: loaded?.max?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final minText = _minController.text.trim().replaceAll(',', '.');
    final maxText = _maxController.text.trim().replaceAll(',', '.');

    final min = minText.isEmpty ? null : double.tryParse(minText);
    final max = maxText.isEmpty ? null : double.tryParse(maxText);

    if (minText.isNotEmpty && min == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Невірний формат мінімального значення')),
      );
      return;
    }
    if (maxText.isNotEmpty && max == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Невірний формат максимального значення'),
        ),
      );
      return;
    }
    if (min != null && max != null && min >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Мінімум має бути менше максимуму'),
        ),
      );
      return;
    }

    widget.cubit.save(widget.sensorId, min, max);
    widget.onSaved(min, max);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThresholdCubit, ThresholdState>(
      bloc: widget.cubit,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Пороги: ${widget.label}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Мінімум (${widget.unit})',
                  hintText: 'Не встановлено',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Максимум (${widget.unit})',
                  hintText: 'Не встановлено',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state is ThresholdLoading
                      ? null
                      : () => _save(context),
                  child: state is ThresholdLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Зберегти'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
