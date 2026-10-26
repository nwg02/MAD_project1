
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HabitDatabase.instance.database;
  runApp(const HabitMasteryApp());
}

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

class HabitMasteryApp extends StatelessWidget {
  const HabitMasteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Mastery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;

  void refresh() => setState(() {});

  Future<void> createHabit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const HabitForm(),
    );
    if (result == true) refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(onChanged: refresh),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Mastery')),
      body: pages[tab],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createHabit,
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  final VoidCallback onChanged;
  const Dashboard({super.key, required this.onChanged});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, Object?>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await HabitDatabase.instance.habits();
    if (!mounted) return;
    setState(() {
      items = result;
      loading = false;
    });
  }

  Future<void> openHabit(Map<String, Object?> habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HabitDetail(habit: habit)),
    );
    await load();
    widget.onChanged();
  }

  Future<void> editHabit(Map<String, Object?> habit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => HabitForm(habit: habit),
    );
    if (result == true) await load();
  }

  Future<void> deleteHabit(Map<String, Object?> habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Delete "${habit['name']}" and its activity history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await HabitDatabase.instance.deleteHabit(habit['id'] as int);
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your habits', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('${items.where((h) => h['is_active'] == 1).length} active habits'),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No habits yet. Tap New habit to get started.'),
            ),
          ...items.map((habit) {
            final active = habit['is_active'] == 1;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(active ? Icons.check_circle_outline : Icons.pause_circle_outline),
                ),
                title: Text(habit['name'] as String),
                subtitle: Text(
                  '${habit['category'] ?? 'General'} • '
                  '${habit['target_amount'] ?? 'No target'} '
                  '${habit['target_unit'] ?? ''}'
                  '${active ? '' : ' • Paused'}',
                ),
                onTap: () => openHabit(habit),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') editHabit(habit);
                    if (value == 'delete') deleteHabit(habit);
                    if (value == 'toggle') toggle(habit);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(active ? 'Pause' : 'Activate'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> toggle(Map<String, Object?> habit) async {
    await HabitDatabase.instance.saveHabit({
      'name': habit['name'],
      'category': habit['category'],
      'target_amount': habit['target_amount'],
      'target_unit': habit['target_unit'],
      'created_at': habit['created_at'],
      'is_active': habit['is_active'] == 1 ? 0 : 1,
    }, id: habit['id'] as int);
    await load();
  }
}

class HabitForm extends StatefulWidget {
  final Map<String, Object?>? habit;
  const HabitForm({super.key, this.habit});

  @override
  State<HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<HabitForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController category;
  late final TextEditingController target;
  late final TextEditingController unit;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    name = TextEditingController(text: h?['name'] as String? ?? '');
    category = TextEditingController(text: h?['category'] as String? ?? '');
    target = TextEditingController(
      text: h?['target_amount']?.toString() ?? '',
    );
    unit = TextEditingController(text: h?['target_unit'] as String? ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    target.dispose();
    unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.habit == null ? 'Create habit' : 'Edit habit'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Habit name *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              TextFormField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Target amount'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v);
                  return n == null || n <= 0 ? 'Enter a number above zero' : null;
                },
              ),
              TextFormField(
                controller: unit,
                decoration: const InputDecoration(labelText: 'Target unit'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    final old = widget.habit;
    await HabitDatabase.instance.saveHabit({
      'name': name.text.trim(),
      'category': category.text.trim().isEmpty ? null : category.text.trim(),
      'target_amount': target.text.trim().isEmpty
          ? null
          : double.parse(target.text.trim()),
      'target_unit': unit.text.trim().isEmpty ? null : unit.text.trim(),
      'created_at': old?['created_at'] ?? DateTime.now().toIso8601String(),
      'is_active': old?['is_active'] ?? 1,
    }, id: old?['id'] as int?);
    if (mounted) Navigator.pop(context, true);
  }
}

class HabitDetail extends StatefulWidget {
  final Map<String, Object?> habit;
  const HabitDetail({super.key, required this.habit});

  @override
  State<HabitDetail> createState() => _HabitDetailState();
}

class _HabitDetailState extends State<HabitDetail> {
  List<Map<String, Object?>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await HabitDatabase.instance.entries(widget.habit['id'] as int);
    if (mounted) setState(() => items = result);
  }

  Future<void> logEntry() async {
    final amountController = TextEditingController(
      text: widget.habit['target_amount']?.toString() ?? '1',
    );
    final noteController = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log activity'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (${widget.habit['target_unit'] ?? 'units'})',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null || n < 0 ? 'Enter a valid amount' : null;
                },
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              Navigator.pop(context, {
                'amount': double.parse(amountController.text),
                'note': noteController.text.trim(),
              });
            },
            child: const Text('Save activity'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final today = DateTime.now();
    final date = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    await HabitDatabase.instance.addEntry({
      'habit_id': widget.habit['id'],
      'entry_date': date,
      'amount': result['amount'],
      'note': (result['note'] as String).isEmpty ? null : result['note'],
      'completed': 1,
    });
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final target = (widget.habit['target_amount'] as num?)?.toDouble();
    final total = items.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] as num).toDouble(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.habit['name'] as String)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: logEntry,
        icon: const Icon(Icons.add),
        label: const Text('Log activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.habit['category'] as String? ?? 'General',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Target: ${target ?? 'Not set'} ${widget.habit['target_unit'] ?? ''}'),
          Text('Total recorded: $total ${widget.habit['target_unit'] ?? ''}'),
          const SizedBox(height: 20),
          Text('Activity history', style: Theme.of(context).textTheme.titleLarge),
          if (items.isEmpty) const Text('No activity recorded yet.'),
          ...items.map((entry) => Card(
            child: ListTile(
              title: Text('${entry['amount']} ${widget.habit['target_unit'] ?? ''}'),
              subtitle: Text('${entry['entry_date']}${entry['note'] == null ? '' : '\n${entry['note']}'}'),
              isThreeLine: entry['note'] != null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete activity?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await HabitDatabase.instance.deleteEntry(entry['id'] as int);
                    await load();
                  }
                },
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, Object?>> entries = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await HabitDatabase.instance.allEntries();
    if (mounted) setState(() => entries = result);
  }

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] as num).toDouble(),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('History & insights', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights),
            title: Text('${entries.length} activity entries'),
            subtitle: Text('Combined recorded amount: $total'),
          ),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty) const Text('Your activity will appear here after you log a habit.'),
        ...entries.map((e) => ListTile(
          title: Text(e['habit_name'] as String),
          subtitle: Text('${e['entry_date']} • ${e['amount']}'
              '${e['note'] == null ? '' : ' • ${e['note']}'}'),
        )),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool reminders = false;
  bool compact = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      reminders = prefs.getBool('reminders') ?? false;
      compact = prefs.getBool('compact') ?? false;
    });
  }

  Future<void> save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        SwitchListTile(
          title: const Text('Daily reminder preference'),
          subtitle: const Text('Stores your preference locally; notifications are not enabled.'),
          value: reminders,
          onChanged: (v) {
            setState(() => reminders = v);
            save('reminders', v);
          },
        ),
        SwitchListTile(
          title: const Text('Compact display'),
          subtitle: const Text('Save your display preference on this device.'),
          value: compact,
          onChanged: (v) {
            setState(() => compact = v);
            save('compact', v);
          },
        ),
        const ListTile(
          leading: Icon(Icons.cloud_off),
          title: Text('Offline-first'),
          subtitle: Text('Habits and activity are stored locally on this device.'),
        ),
      ],
    );
  }
}
