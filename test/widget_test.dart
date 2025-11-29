// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.
//
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// import 'package:diplom/main.dart';
//
// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(MyApp());
//
//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);
//
//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();
//
//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }

import 'package:diplom/model_services/tflite_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diplom/main.dart';
import 'package:mockito/mockito.dart';

// Создаем мок-класс для TFLiteService
class MockTFLiteService extends Mock implements TFLiteService {}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Создаем моковый объект
    final mockTFLiteService = MockTFLiteService();

    // Запускаем приложение с моковым сервисом
    await tester.pumpWidget(MyApp(tfliteService: mockTFLiteService));

    // Проверяем, что начальное значение счетчика — 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Имитация нажатия на кнопку "+"
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Проверяем, что счетчик увеличился до 1
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
