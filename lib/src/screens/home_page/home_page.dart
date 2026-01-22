import 'package:flutter/material.dart';

import 'package:test1/src/widgets/chipi_dizel_connector/chipi_dizel_connector.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade300,
            Colors.orange.shade700,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Верхній заголовок
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.power_settings_new,
                    size: 40,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Чіпідізєль Smart Station',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Основний контент (віджет підключення)
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 50,
                      left: 24,
                      right: 24,),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.amber.shade100,
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: ChipiDizelConnector(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Кнопка переходу до станції
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/station'),
                child: const Text('Перейти до станції'),
              ),
            ),
            // Нижній напис
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Ласкаво просимо до розумного дому!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
