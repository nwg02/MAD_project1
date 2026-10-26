
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

  test('creates and retrieves a habit', () async {
    final id = await db.insert('Habit', {
      'name': 'Read',
      'created_at': DateTime.now().toIso8601String(),
    });

    final habits = await db.query(
      'Habit',
      where: 'id = ?',
      whereArgs: [id],
    );

    expect(habits, hasLength(1));
    expect(habits.first['name'], 'Read');
  });

  test('updates a habit name', () async {
    final id = await db.insert('Habit', {
      'name': 'Read',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.update(
      'Habit',
      {'name': 'Read daily'},
      where: 'id = ?',
      whereArgs: [id],
    );

    final habit = (await db.query(
      'Habit',
      where: 'id = ?',
      whereArgs: [id],
    )).first;

    expect(habit['name'], 'Read daily');
  });

  test('deletes a habit', () async {
    final id = await db.insert('Habit', {
      'name': 'Read',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.delete('Habit', where: 'id = ?', whereArgs: [id]);

    final habits = await db.query('Habit');
    expect(habits, isEmpty);
  });
}
