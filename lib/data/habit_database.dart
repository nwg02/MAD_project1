
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class HabitDatabase {
  HabitDatabase._();
  static final instance = HabitDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'habit_mastery.db');
    _db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
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
        await db.execute('''
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
    return _db!;
  }

  Future<List<Map<String, Object?>>> habits({bool activeOnly = false}) async {
    final db = await database;
    return db.query(
      'Habit',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name COLLATE NOCASE',
    );
  }

  Future<int> saveHabit(Map<String, Object?> values, {int? id}) async {
    final db = await database;
    if (id == null) return db.insert('Habit', values);
    return db.update('Habit', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteHabit(int id) async {
    final db = await database;
    await db.delete('Habit', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addEntry(Map<String, Object?> values) async {
    final db = await database;
    return db.insert('HabitEntry', values);
  }

  Future<List<Map<String, Object?>>> entries(int habitId) async {
    final db = await database;
    return db.query(
      'HabitEntry',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'entry_date DESC, id DESC',
    );
  }

  Future<List<Map<String, Object?>>> allEntries() async {
    final db = await database;
    return db.rawQuery('''
      SELECT HabitEntry.*, Habit.name AS habit_name
      FROM HabitEntry
      JOIN Habit ON Habit.id = HabitEntry.habit_id
      ORDER BY entry_date DESC, HabitEntry.id DESC
    ''');
  }

  Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete('HabitEntry', where: 'id = ?', whereArgs: [id]);
  }
}
