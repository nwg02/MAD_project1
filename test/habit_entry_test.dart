
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late int habitId;

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

    habitId = await db.insert('Habit', {
      'name': 'Read',
      'created_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('records and retrieves a habit entry', () async {
    await db.insert('HabitEntry', {
      'habit_id': habitId,
      'entry_date': '2026-10-26',
      'amount': 20.0,
      'note': 'Read two chapters',
      'completed': 1,
    });

    final entries = await db.query(
      'HabitEntry',
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );

    expect(entries, hasLength(1));
    expect(entries.first['amount'], 20.0);
    expect(entries.first['note'], 'Read two chapters');
  });

  test('deletes a habit entry', () async {
    final entryId = await db.insert('HabitEntry', {
      'habit_id': habitId,
      'entry_date': '2026-10-26',
      'amount': 20.0,
      'completed': 1,
    });

    await db.delete(
      'HabitEntry',
      where: 'id = ?',
      whereArgs: [entryId],
    );

    expect(await db.query('HabitEntry'), isEmpty);
  });
}
