import 'package:flutter/material.dart';
import 'package:test1/src/screens/home_page/home_page.dart';
import 'package:test1/src/screens/login_page/login_page.dart';
import 'package:test1/src/screens/register_page/register_page.dart';
import 'package:test1/src/screens/smart_station_page/smart_station_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Smart Home: Чіпідізєль',
    theme: ThemeData(
      primarySwatch: Colors.teal,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    routes: {
      '/': (context) => const LoginPage(),
      '/register': (context) => const RegisterPage(),
      '/station': (context) => const SmartStationPage(),
      '/home': (context) => const HomePage(),
    },
  );
}
