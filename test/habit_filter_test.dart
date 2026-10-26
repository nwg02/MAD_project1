
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE Habit(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT,
            target_amount REAL,
            target_unit TEXT,
            created_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('active-only query excludes paused habits', () async {
    await db.insert('Habit', {
      'name': 'Read',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });

    await db.insert('Habit', {
      'name': 'Exercise',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 0,
    });

    final activeHabits = await db.query(
      'Habit',
      where: 'is_active = 1',
    );

    expect(activeHabits, hasLength(1));
    expect(activeHabits.first['name'], 'Read');
  });

  test('habit can be paused and reactivated', () async {
    final id = await db.insert('Habit', {
      'name': 'Read',
      'created_at': DateTime.now().toIso8601String(),
      'is_active': 1,
    });

    await db.update(
      'Habit',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    var habit = (await db.query(
      'Habit',
      where: 'id = ?',
      whereArgs: [id],
    )).first;

    expect(habit['is_active'], 0);

    await db.update(
      'Habit',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    habit = (await db.query(
      'Habit',
      where: 'id = ?',
      whereArgs: [id],
    )).first;

    expect(habit['is_active'], 1);
  });
}
