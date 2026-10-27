
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/habit_database.dart';
import 'data/habit_suggestion.dart';

const Color charcoal = Color(0xFF303030);
const Color charcoalLight = Color(0xFF484848);
const Color pageBackground = Color(0xFFF7F7F7);
const Color borderColor = Color(0xFFD6D6D6);
const Color mutedText = Color(0xFF595959);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HabitDatabase.instance.database;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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
        useMaterial3: true,
        scaffoldBackgroundColor: pageBackground,
        colorScheme: const ColorScheme.light(
          primary: charcoal,
          onPrimary: Colors.white,
          secondary: charcoalLight,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF202020),
          outline: borderColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: charcoal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: charcoal,
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderColor),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: charcoal),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: const BorderSide(color: charcoal, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: charcoal,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: charcoal,
            minimumSize: const Size(100, 46),
            side: const BorderSide(color: charcoalLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: charcoal,
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: charcoal,
          height: 76,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : charcoal,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
            (states) => TextStyle(
              color: charcoal,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        dividerColor: borderColor,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: charcoal,
          linearTrackColor: Color(0xFFE6E6E6),
        ),
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

  void refresh() {
    setState(() {});
  }

  Future<void> createHabit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const HabitForm(),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(onChanged: refresh),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(title: const Text('Habit Mastery')),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(
              onPressed: createHabit,
              backgroundColor: charcoal,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add),
              label: const Text(
                'New habit',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
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

    if (!mounted) return;
    await load();
    widget.onChanged();
  }

  Future<void> editHabit(Map<String, Object?> habit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => HabitForm(habit: habit),
    );

    if (result == true && mounted) {
      await load();
      widget.onChanged();
    }
  }

  Future<void> deleteHabit(Map<String, Object?> habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'Delete "${habit['name']}" and its activity history?',
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
      await HabitDatabase.instance.deleteHabit(habit['id'] as int);
      if (!mounted) return;
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

    if (!mounted) return;
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

    return RefreshIndicator(
      onRefresh: load,
      color: charcoal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          Text(
            'Your habits',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: charcoal,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '${activeHabits.length} active '
            '${activeHabits.length == 1 ? 'habit' : 'habits'}',
            style: const TextStyle(color: mutedText, fontSize: 15),
          ),
          const SizedBox(height: 22),
          if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.track_changes, size: 42, color: charcoal),
                    const SizedBox(height: 12),
                    const Text(
                      'Start building a habit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first habit to start tracking your progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedText),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (_) => const HabitForm(),
                        );
                        if (result == true && mounted) await load();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create habit'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...items.map((habit) {
              final active = habit['is_active'] == 1;
              final target = habit['target_amount'];
              final unit = habit['target_unit'] as String? ?? '';
              final category = habit['category'] as String? ?? 'General';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => openHabit(habit),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFEAEAEA)
                                  : const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              active
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              color: charcoal,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: charcoal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$category • ${target ?? 'No target'}'
                                  '${unit.isEmpty ? '' : ' $unit'}',
                                  style: const TextStyle(
                                    color: mutedText,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!active) ...[
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Paused',
                                    style: TextStyle(
                                      color: charcoal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Habit options',
                            icon: const Icon(Icons.more_vert, color: charcoal),
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
    final habit = widget.habit;

    name = TextEditingController(text: habit?['name'] as String? ?? '');
    category =
        TextEditingController(text: habit?['category'] as String? ?? '');
    target =
        TextEditingController(text: habit?['target_amount']?.toString() ?? '');
    unit =
        TextEditingController(text: habit?['target_unit'] as String? ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    target.dispose();
    unit.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.habit != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Text(
        editing ? 'Edit habit' : 'Create habit',
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: charcoal,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing ? 'Habit setup · ${name.text}' : 'Habit setup',
                  style: const TextStyle(color: mutedText, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: name,
                  decoration: fieldDecoration('Habit name *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a habit name'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: category,
                  decoration: fieldDecoration('Category'),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: target,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: fieldDecoration('Goal'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null ||
                              !amount.isFinite ||
                              amount <= 0) {
                            return 'Enter a positive number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: unit,
                        decoration: fieldDecoration('Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  target.text.trim().isEmpty
                      ? 'You can set a target and unit for your habit.'
                      : 'Target: ${target.text} ${unit.text}. '
                          'Past activity records are kept.',
                  style: const TextStyle(color: mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
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
      'category':
          category.text.trim().isEmpty ? null : category.text.trim(),
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
    final result =
        await HabitDatabase.instance.entries(widget.habit['id'] as int);

    if (mounted) setState(() => items = result);
  }

  // Uses initialValue/onSaved rather than TextEditingController.
  // This avoids disposing controllers while the dialog is animating closed.
  Future<void> logEntry() async {
    final formKey = GlobalKey<FormState>();

    String amountText =
        widget.habit['target_amount']?.toString() ?? '1';
    String noteText = '';

    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log activity'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: amountText,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText:
                        'Amount (${widget.habit['target_unit'] ?? 'units'})',
                  ),
                  onSaved: (value) => amountText = value?.trim() ?? '',
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null ||
                        !amount.isFinite ||
                        amount < 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '',
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                  onSaved: (value) => noteText = value?.trim() ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();

              Navigator.pop(dialogContext, {
                'amount': double.parse(amountText),
                'note': noteText,
              });
            },
            child: const Text('Save activity'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

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
                Icon(Icons.lightbulb_outline, color: charcoal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next-Step Habit Suggestion',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: charcoal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(suggestion.reason),
            const SizedBox(height: 10),
            Text(
              'Suggested target: '
              '${suggestion.recommendedAmount.toStringAsFixed(1)} '
              '${widget.habit['target_unit'] ?? ''}',
            ),
            const SizedBox(height: 12),
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
                  onPressed: () => setState(() => suggestionDismissed = true),
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
      (sum, entry) => sum + (entry['amount'] as num).toDouble(),
    );

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(title: Text(widget.habit['name'] as String)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: logEntry,
        backgroundColor: charcoal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          Text(
            widget.habit['category'] as String? ?? 'General',
            style: const TextStyle(
              color: mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current target',
                      style: TextStyle(color: mutedText)),
                  const SizedBox(height: 5),
                  Text(
                    '${target ?? 'Not set'} ${widget.habit['target_unit'] ?? ''}',
                    style: const TextStyle(
                      color: charcoal,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Divider(height: 24),
                  const Text('Total recorded',
                      style: TextStyle(color: mutedText)),
                  const SizedBox(height: 5),
                  Text(
                    '$total ${widget.habit['target_unit'] ?? ''}',
                    style: const TextStyle(
                      color: charcoal,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!suggestionDismissed) suggestionCard(suggestion, target),
          const SizedBox(height: 22),
          Text(
            'Activity history',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: charcoal,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No activity recorded yet. Tap Log activity to add your first entry.',
                  style: TextStyle(color: mutedText),
                ),
              ),
            )
          else
            ...items.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    title: Text(
                      '${entry['amount']} ${widget.habit['target_unit'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${entry['entry_date']}'
                      '${entry['note'] == null ? '' : '\n${entry['note']}'}',
                    ),
                    isThreeLine: entry['note'] != null,
                    trailing: IconButton(
                      tooltip: 'Delete activity',
                      icon: const Icon(Icons.delete_outline, color: charcoal),
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
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
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
        : entries
            .where((entry) => entry['habit_id'] == selectedHabitId)
            .toList();

    final total = filteredEntries.fold<double>(
      0,
      (sum, entry) => sum + (entry['amount'] as num).toDouble(),
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
      final habitName = entry['habit_name'] as String;
      final summary = habitSummaries.putIfAbsent(
        habitName,
        () => {'count': 0, 'total': 0.0},
      );
      summary['count'] = (summary['count'] as int) + 1;
      summary['total'] =
          (summary['total'] as double) + (entry['amount'] as num).toDouble();
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 16,
        20,
        compact ? 10 : 16,
        24,
      ),
      children: [
        Text(
          'History & insights',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: charcoal,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 18),
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
          onChanged: (value) => setState(() => selectedHabitId = value),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 14),
                  child: Icon(Icons.insights, color: charcoal, size: 25),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${filteredEntries.length} activity entries',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatLine(
                        label: 'Combined recorded amount',
                        value: total.toStringAsFixed(1),
                      ),
                      _StatLine(
                        label: 'Average per entry',
                        value: average.toStringAsFixed(1),
                      ),
                      _StatLine(
                        label: 'Completion rate',
                        value: '${completionRate.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Progress by habit',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: charcoal,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        if (habitSummaries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No progress summaries available yet.',
                style: TextStyle(color: mutedText),
              ),
            ),
          )
        else
          ...habitSummaries.entries.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: charcoal,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${item.value['count']} activity entries',
                              style: const TextStyle(color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Total: ${(item.value['total'] as double).toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Recent activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: charcoal,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (filteredEntries.isEmpty)
          const Text(
            'No activity found for this selection.',
            style: TextStyle(color: mutedText),
          )
        else
          ...filteredEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  dense: compact,
                  title: Text(
                    entry['habit_name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${entry['entry_date']} • ${entry['amount']}'
                    '${entry['note'] == null ? '' : ' • ${entry['note']}'}',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 5,
        children: [
          Text('$label:', style: const TextStyle(color: mutedText)),
          Text(
            value,
            style: const TextStyle(
              color: charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: charcoal,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                activeTrackColor: charcoal,
                title: const Text(
                  'Daily reminder preference',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Stores your preference locally; notifications are not enabled.',
                ),
                value: reminders,
                onChanged: (value) {
                  setState(() => reminders = value);
                  save('reminders', value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                activeTrackColor: charcoal,
                title: const Text(
                  'Compact display',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Save your display preference on this device.',
                ),
                value: compact,
                onChanged: (value) {
                  setState(() => compact = value);
                  save('compact', value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.cloud_off, color: charcoal),
            title: Text(
              'Offline-first',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Habits and activity are stored locally on this device.',
            ),
          ),
        ),
      ],
    );
  }
}
