import 'package:flutter_test/flutter_test.dart';
import 'package:test1/main.dart';

void main() {
  testWidgets('Navigation flow test', (WidgetTester tester) async {
    // Запуск додатку
    await tester.pumpWidget(const MyApp());

    // Перевірка, що відкривається LoginPage
    expect(find.text('Логін'), findsOneWidget);
    expect(find.text('Реєстрація'), findsOneWidget);

    // Перехід до RegistrationPage
    await tester.tap(find.text('Реєстрація'));
    await tester.pumpAndSettle();

    // Перевірка, що відкривається RegistrationPage
    expect(find.text('Реєстрація'), findsOneWidget);
    expect(find.text('Зареєструватись'), findsOneWidget);

    // Перехід до SmartStationPage
    await tester.tap(find.text('Зареєструватись'));
    await tester.pumpAndSettle();

    // Перевірка, що відкривається SmartStationPage
    expect(find.text('Станція Чіпідізєль'), findsOneWidget);
    expect(find.text('Головна'), findsOneWidget);

    // Перехід до HomePage
    await tester.tap(find.text('Головна'));
    await tester.pumpAndSettle();

    // Перевірка, що відкривається HomePage
    expect(find.text('Чіпідізєль Smart Station'), findsOneWidget);
    expect(find.text('Ласкаво просимо до розумного дому!'), findsOneWidget);
  });
}
