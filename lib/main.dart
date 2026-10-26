
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/habit_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HabitDatabase.instance.database;
  runApp(const HabitMasteryApp());
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
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
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

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Your habits',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
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
                  child: Icon(
                    active
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                  ),
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(active ? 'Pause' : 'Activate'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: target,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Target amount'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v);
                  return n == null || n <= 0
                      ? 'Enter a number above zero'
                      : null;
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
    final result =
        await HabitDatabase.instance.entries(widget.habit['id'] as int);
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText:
                      'Amount (${widget.habit['target_unit'] ?? 'units'})',
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null || !n.isFinite || n < 0
                      ? 'Enter a valid amount'
                      : null;
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
          Text(
            'Target: ${target ?? 'Not set'} '
            '${widget.habit['target_unit'] ?? ''}',
          ),
          Text(
            'Total recorded: $total ${widget.habit['target_unit'] ?? ''}',
          ),
          const SizedBox(height: 20),
          Text(
            'Activity history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (items.isEmpty) const Text('No activity recorded yet.'),
          ...items.map(
            (entry) => Card(
              child: ListTile(
                title: Text(
                  '${entry['amount']} ${widget.habit['target_unit'] ?? ''}',
                ),
                subtitle: Text(
                  '${entry['entry_date']}'
                  '${entry['note'] == null ? '' : '\n${entry['note']}'}',
                ),
                isThreeLine: entry['note'] != null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete activity?'),
                        content: const Text(
                          'This activity entry will be permanently deleted.',
                        ),
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
                      await HabitDatabase.instance
                          .deleteEntry(entry['id'] as int);
                      await load();
                    }
                  },
                ),
              ),
            ),
          ),
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
  List<Map<String, Object?>> habits = [];
  int? selectedHabitId;
  bool loading = true;
  bool compact = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final results = await Future.wait([
      HabitDatabase.instance.allEntries(),
      HabitDatabase.instance.habits(),
    ]);

    final prefs = await SharedPreferences.getInstance();
    final compactSetting = prefs.getBool('compact') ?? false;

    if (!mounted) return;

    setState(() {
      entries = results[0];
      habits = results[1];
      compact = compactSetting;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = selectedHabitId == null
        ? entries
        : entries.where((e) => e['habit_id'] == selectedHabitId).toList();

    final total = filteredEntries.fold<double>(
      0,
      (sum, e) => sum + (e['amount'] as num).toDouble(),
    );

    final average =
        filteredEntries.isEmpty ? 0.0 : total / filteredEntries.length;

    final completedCount =
        filteredEntries.where((entry) => entry['completed'] == 1).length;

    final completionRate = filteredEntries.isEmpty
        ? 0.0
        : completedCount / filteredEntries.length * 100;

    final habitSummaries = <String, Map<String, Object?>>{};

    for (final entry in filteredEntries) {
      final name = entry['habit_name'] as String;
      final summary = habitSummaries.putIfAbsent(
        name,
        () => {'count': 0, 'total': 0.0},
      );

      summary['count'] = (summary['count'] as int) + 1;
      summary['total'] =
          (summary['total'] as double) + (entry['amount'] as num).toDouble();
    }

    return ListView(
      padding: EdgeInsets.all(compact ? 8 : 16),
      children: [
        Text(
          'History & insights',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: compact ? 6 : 12),
        DropdownButtonFormField<int?>(
          initialValue: selectedHabitId,
          decoration: const InputDecoration(
            labelText: 'Filter by habit',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('All habits'),
            ),
            ...habits.map(
              (habit) => DropdownMenuItem<int?>(
                value: habit['id'] as int,
                child: Text(habit['name'] as String),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => selectedHabitId = value);
          },
        ),
        SizedBox(height: compact ? 6 : 12),
        Card(
          child: ListTile(
            visualDensity:
                compact ? VisualDensity.compact : VisualDensity.standard,
            leading: const Icon(Icons.insights),
            title: Text('${filteredEntries.length} activity entries'),
            subtitle: Text(
              'Combined recorded amount: ${total.toStringAsFixed(1)}\n'
              'Average per entry: ${average.toStringAsFixed(1)}\n'
              'Completion rate: ${completionRate.toStringAsFixed(1)}%',
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 12),
        Text(
          'Progress by habit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: compact ? 4 : 8),
        if (habitSummaries.isEmpty)
          const Text('No progress summaries available yet.')
        else
          ...habitSummaries.entries.map(
            (item) => Card(
              child: ListTile(
                visualDensity:
                    compact ? VisualDensity.compact : VisualDensity.standard,
                title: Text(item.key),
                subtitle: Text('${item.value['count']} activity entries'),
                trailing: Text(
                  'Total: ${(item.value['total'] as double).toStringAsFixed(1)}',
                ),
              ),
            ),
          ),
        SizedBox(height: compact ? 4 : 8),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (filteredEntries.isEmpty)
          const Text('No activity found for this selection.')
        else
          ...filteredEntries.map(
            (e) => ListTile(
              visualDensity:
                  compact ? VisualDensity.compact : VisualDensity.standard,
              title: Text(e['habit_name'] as String),
              subtitle: Text(
                '${e['entry_date']} • ${e['amount']}'
                '${e['note'] == null ? '' : ' • ${e['note']}'}',
              ),
            ),
          ),
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
          subtitle: const Text(
            'Stores your preference locally; notifications are not enabled.',
          ),
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
          subtitle: Text(
            'Habits and activity are stored locally on this device.',
          ),
        ),
      ],
    );
  }
}
