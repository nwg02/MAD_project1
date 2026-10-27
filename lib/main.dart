import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/habit_database.dart';
import 'data/habit_suggestion.dart';

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
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
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
  Map<int, double> todayAmounts = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await HabitDatabase.instance.habits();
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final amounts = <int, double>{};

    for (final habit in result) {
      final id = habit['id'] as int;
      final entries = await HabitDatabase.instance.entries(id);

      amounts[id] = entries
          .where((entry) => (entry['entry_date'] as String).startsWith(today))
          .fold<double>(
            0,
            (sum, entry) => sum + (entry['amount'] as num).toDouble(),
          );
    }

    if (!mounted) return;
    setState(() {
      items = result;
      todayAmounts = amounts;
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
    if (result == true) {
      await load();
      widget.onChanged();
    }
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
      widget.onChanged();
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
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeHabits =
        items.where((habit) => habit['is_active'] == 1).toList();

    final completed = activeHabits.where((habit) {
      final target = (habit['target_amount'] as num?)?.toDouble() ?? 0;
      return target > 0 &&
          (todayAmounts[habit['id'] as int] ?? 0) >= target;
    }).length;

    final progress =
        activeHabits.isEmpty ? 0.0 : completed / activeHabits.length;

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Text(
            'Your habits',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Small steps, consistent progress.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "TODAY'S PROGRESS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.wb_sunny_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$completed of ${activeHabits.length} habits reached',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor:
                        Theme.of(context).colorScheme.surface.withAlpha(130),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  activeHabits.isEmpty
                      ? 'Add a habit to start tracking your progress.'
                      : completed == activeHabits.length
                          ? 'Great work! You reached every active target today.'
                          : 'Keep going. Every entry moves you forward.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's habits",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                '${activeHabits.length} active',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.spa_outlined, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Start with one small habit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap New habit to get started.'),
                  ],
                ),
              ),
            ),
          ...items.map((habit) {
            final active = habit['is_active'] == 1;
            final id = habit['id'] as int;
            final amount = todayAmounts[id] ?? 0;
            final target =
                (habit['target_amount'] as num?)?.toDouble() ?? 0;
            final ratio = target > 0
                ? (amount / target).clamp(0.0, 1.0).toDouble()
                : 0.0;
            final reached = target > 0 && amount >= target;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => openHabit(habit),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondaryContainer,
                            child: Icon(
                              reached
                                  ? Icons.check_rounded
                                  : Icons.spa_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit['name'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${habit['category'] ?? 'General'}'
                                  '${active ? '' : ' • Paused'}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
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
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              target > 0
                                  ? '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}'
                                      ' / ${target.toStringAsFixed(target % 1 == 0 ? 0 : 1)}'
                                      ' ${habit['target_unit'] ?? ''}'
                                  : 'No target set',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            target > 0
                                ? '${(ratio * 100).round()}%'
                                : 'Set a target',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                        ),
                      ),
                      if (reached) ...[
                        const SizedBox(height: 10),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, size: 18),
                            SizedBox(width: 6),
                            Text('Daily target reached'),
                          ],
                        ),
                      ],
                    ],
                  ),
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
    target = TextEditingController(text: h?['target_amount']?.toString() ?? '');
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Target amount'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v);
                  return n == null || !n.isFinite || n <= 0
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
        FilledButton(onPressed: save, child: const Text('Save')),
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
  double? targetOverride;
  bool suggestionDismissed = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await HabitDatabase.instance.entries(
      widget.habit['id'] as int,
    );
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
    final date =
        '${today.year.toString().padLeft(4, '0')}-'
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

  Future<void> applySuggestion(double amount) async {
    final updatedHabit = Map<String, Object?>.from(widget.habit);
    updatedHabit['target_amount'] = amount;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => HabitForm(habit: updatedHabit),
    );

    if (saved != true || !mounted) return;

    final savedHabits = await HabitDatabase.instance.habits();
    final savedHabit = savedHabits.firstWhere(
      (habit) => habit['id'] == widget.habit['id'],
    );

    setState(() {
      targetOverride = (savedHabit['target_amount'] as num?)?.toDouble();
      suggestionDismissed = true;
    });
  }

  Widget suggestionCard(HabitSuggestion suggestion, double? target) {
    final canApply =
        target != null && target.isFinite && target > 0 && items.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next-Step Habit Suggestion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(suggestion.reason),
            const SizedBox(height: 8),
            Text(
              'Suggested target: '
              '${suggestion.recommendedAmount.toStringAsFixed(1)} '
              '${widget.habit['target_unit'] ?? ''}',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (canApply)
                  FilledButton(
                    onPressed: () =>
                        applySuggestion(suggestion.recommendedAmount),
                    child: const Text('Apply'),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() => suggestionDismissed = true);
                  },
                  child: const Text('Not now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target =
        targetOverride ?? (widget.habit['target_amount'] as num?)?.toDouble();

    final suggestion = suggestNextTarget(
      currentTarget: target ?? 0,
      recentAmounts: items
          .take(5)
          .map((entry) => (entry['amount'] as num).toDouble())
          .toList(),
    );

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
          Text('Total recorded: $total ${widget.habit['target_unit'] ?? ''}'),
          const SizedBox(height: 16),
          if (!suggestionDismissed) suggestionCard(suggestion, target),
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
                      await HabitDatabase.instance.deleteEntry(
                        entry['id'] as int,
                      );
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

    final average = filteredEntries.isEmpty
        ? 0.0
        : total / filteredEntries.length;

    final completedCount = filteredEntries
        .where((entry) => entry['completed'] == 1)
        .length;

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
            visualDensity: compact
                ? VisualDensity.compact
                : VisualDensity.standard,
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
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
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
              visualDensity: compact
                  ? VisualDensity.compact
                  : VisualDensity.standard,
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
