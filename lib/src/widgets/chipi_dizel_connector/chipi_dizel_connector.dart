import 'package:flutter/material.dart';

class ChipiDizelConnector extends StatefulWidget {
  const ChipiDizelConnector({super.key});

  @override
  ChipiDizelConnectorState createState() => ChipiDizelConnectorState();
}

class ChipiDizelConnectorState extends State<ChipiDizelConnector> {
  bool connected = false;

  void _toggleConnection() => setState(() => connected = !connected);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        connected ? 'Підключено до Чіпідізєль' : 'Не підключено',
        style: const TextStyle(fontSize: 18),
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: connected ? Colors.redAccent : Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: _toggleConnection,
        child: Text(connected ? 'Відключитись' : 'Підключитись'),
      ),
    ],
  );
}
