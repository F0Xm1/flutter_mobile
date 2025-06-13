import 'package:flutter_test/flutter_test.dart';
import 'package:test1/main.dart';

void main() {
  testWidgets('Navigation flow test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Логін'), findsOneWidget);
    expect(find.text('Реєстрація'), findsOneWidget);

    await tester.tap(find.text('Реєстрація'));
    await tester.pumpAndSettle();

    expect(find.text('Реєстрація'), findsOneWidget);
    expect(find.text('Зареєструватись'), findsOneWidget);

    await tester.tap(find.text('Зареєструватись'));
    await tester.pumpAndSettle();

    expect(find.text('Станція Чіпідізєль'), findsOneWidget);
    expect(find.text('Головна'), findsOneWidget);

    await tester.tap(find.text('Головна'));
    await tester.pumpAndSettle();

    expect(find.text('Чіпідізєль Smart Station'), findsOneWidget);
    expect(find.text('Ласкаво просимо до розумного дому!'), findsOneWidget);
  });
}
