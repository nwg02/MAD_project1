
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
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
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
        await database.execute('''
          CREATE TABLE HabitEntry(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            entry_date TEXT NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            completed INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(habit_id) REFERENCES Habit(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('database creates Habit and HabitEntry tables', () async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((row) => row['name']).toSet();

    expect(names, contains('Habit'));
    expect(names, contains('HabitEntry'));
  });

  test('deleting a habit deletes its entries', () async {
    final habitId = await db.insert('Habit', {
      'name': 'Read',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('HabitEntry', {
      'habit_id': habitId,
      'entry_date': DateTime.now().toIso8601String(),
      'amount': 10.0,
      'completed': 1,
    });

    await db.delete('Habit', where: 'id = ?', whereArgs: [habitId]);

    final entries = await db.query('HabitEntry');
    expect(entries, isEmpty);
  });

  test('an entry cannot reference a nonexistent habit', () async {
    expect(
      () => db.insert('HabitEntry', {
        'habit_id': 999,
        'entry_date': DateTime.now().toIso8601String(),
        'amount': 1.0,
        'completed': 0,
      }),
      throwsA(anything),
    );
  });
}
