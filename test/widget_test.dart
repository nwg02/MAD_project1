import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Habit Mastery launches', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitMasteryApp());
    await tester.pump();

    expect(find.text('Habit Mastery'), findsOneWidget);
  });
}