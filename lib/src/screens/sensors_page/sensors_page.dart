import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/presentation/cubits/sensors_cubit.dart';

class SensorsPage extends StatefulWidget {
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  late final SensorsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SensorsCubit();
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showAddLocationSheet() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: _AddLocationSheet(
          onSuccess: () => messenger.showSnackBar(
            const SnackBar(content: Text('Локацію додано')),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SensorsCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1B2D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1B2D),
          foregroundColor: Colors.white,
          title: const Text('Сенсори'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Додати локацію',
              onPressed: _showAddLocationSheet,
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1B2D), Color(0xFF25274D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            BlocBuilder<SensorsCubit, SensorsState>(
              builder: (context, state) {
                if (state is SensorsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                if (state is SensorsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                context.read<SensorsCubit>().load(),
                            child: const Text(
                              'Спробувати знову',
                              style: TextStyle(color: Colors.tealAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is SensorsLoaded) {
                  if (state.locations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_off_outlined,
                            color: Colors.white24,
                            size: 72,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Додайте першу локацію',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: _showAddLocationSheet,
                            icon: const Icon(
                              Icons.add,
                              color: Colors.tealAccent,
                            ),
                            label: const Text(
                              'Додати локацію',
                              style: TextStyle(color: Colors.tealAccent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.tealAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => context.read<SensorsCubit>().load(),
                    color: const Color(0xFF8A2BE2),
                    backgroundColor: const Color(0xFF25274D),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: state.locations.length,
                      itemBuilder: (context, index) {
                        final location = state.locations[index];
                        final sensors =
                            state.sensorsByLocation[location['id'] as String] ??
                                [];
                        return _LocationTile(
                          location: location,
                          sensors: sensors,
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final Map<String, dynamic> location;
  final List<Map<String, dynamic>> sensors;

  const _LocationTile({required this.location, required this.sensors});

  @override
  Widget build(BuildContext context) {
    final id = location['id'] as String;
    final name = location['name'] as String;
    final address = (location['address'] as String?) ?? '';

    return Dismissible(
      key: Key('location-$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF25274D),
          title: const Text(
            'Видалити локацію?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Видалити локацію разом з усіма сенсорами?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Видалити',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        context.read<SensorsCubit>().deleteLocation(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Локацію "$name" видалено')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.redAccent,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: ExpansionTile(
          collapsedIconColor: Colors.white38,
          iconColor: Colors.white60,
          leading: const Icon(
            Icons.location_on_outlined,
            color: Colors.tealAccent,
          ),
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: address.isNotEmpty
              ? Text(
                  address,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                )
              : null,
          children: [
            if (sensors.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Сенсорів немає',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ...sensors.map((sensor) => _SensorTile(sensor: sensor)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: OutlinedButton.icon(
                onPressed: () => _showAddSensorSheet(context, id),
                icon: const Icon(Icons.add, color: Colors.tealAccent, size: 18),
                label: const Text(
                  'Додати сенсор',
                  style: TextStyle(color: Colors.tealAccent, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.tealAccent, width: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSensorSheet(BuildContext context, String locationId) {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<SensorsCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _AddSensorSheet(
          locationId: locationId,
          onSuccess: () => messenger.showSnackBar(
            const SnackBar(content: Text('Сенсор додано')),
          ),
        ),
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final Map<String, dynamic> sensor;

  const _SensorTile({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final id = sensor['id'] as String;
    final name = sensor['name'] as String;
    final type = sensor['type'] as String;
    final unit = sensor['unit'] as String;

    return Dismissible(
      key: Key('sensor-$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF25274D),
          title: const Text(
            'Видалити сенсор?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Видалити "$name"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Видалити',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        context.read<SensorsCubit>().deleteSensor(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сенсор "$name" видалено')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.redAccent,
          size: 22,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(
          _iconFor(type),
          color: Colors.tealAccent.withValues(alpha: 0.7),
          size: 22,
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          _labelFor(type),
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Text(
          unit,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'temperature' => Icons.thermostat,
        'humidity' => Icons.water_drop_outlined,
        _ => Icons.speed,
      };

  String _labelFor(String type) => switch (type) {
        'temperature' => 'Температура',
        'humidity' => 'Вологість',
        _ => 'Тиск',
      };
}

class _AddLocationSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const _AddLocationSheet({required this.onSuccess});

  @override
  State<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<_AddLocationSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF25274D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Нова локація',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _DarkTextField(controller: _nameController, label: 'Назва'),
          const SizedBox(height: 12),
          _DarkTextField(controller: _addressController, label: 'Адреса'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Додати'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final address = _addressController.text.trim();
    setState(() => _isSubmitting = true);
    final cubit = context.read<SensorsCubit>();
    await cubit.addLocation(name, address);
    if (!mounted) return;
    Navigator.pop(context);
    if (cubit.state is SensorsLoaded) {
      widget.onSuccess();
    }
  }
}

class _AddSensorSheet extends StatefulWidget {
  final String locationId;
  final VoidCallback onSuccess;

  const _AddSensorSheet({required this.locationId, required this.onSuccess});

  @override
  State<_AddSensorSheet> createState() => _AddSensorSheetState();
}

class _AddSensorSheetState extends State<_AddSensorSheet> {
  final _nameController = TextEditingController();
  String _selectedType = 'temperature';
  bool _isSubmitting = false;

  static const _types = <String, (String, String)>{
    'temperature': ('Температура', '°C'),
    'humidity': ('Вологість', '%'),
    'pressure': ('Тиск', 'hPa'),
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final (_, unit) = _types[_selectedType]!;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF25274D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Новий сенсор',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _DarkTextField(controller: _nameController, label: 'Назва сенсора'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedType,
            dropdownColor: const Color(0xFF1A1B2D),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Тип',
              labelStyle: const TextStyle(color: Colors.white54),
              fillColor: Colors.white.withValues(alpha: 0.05),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.tealAccent),
              ),
            ),
            items: _types.entries.map((e) {
              final (label, _) = e.value;
              return DropdownMenuItem(value: e.key, child: Text(label));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Одиниця: ',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Додати'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final (_, unit) = _types[_selectedType]!;
    setState(() => _isSubmitting = true);
    final cubit = context.read<SensorsCubit>();
    await cubit.addSensor(widget.locationId, name, _selectedType, unit);
    if (!mounted) return;
    Navigator.pop(context);
    if (cubit.state is SensorsLoaded) {
      widget.onSuccess();
    }
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DarkTextField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        fillColor: Colors.white.withValues(alpha: 0.05),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent),
        ),
      ),
    );
  }
}
