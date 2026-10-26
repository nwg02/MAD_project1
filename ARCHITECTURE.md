# Habit Mastery — Architecture

## 1. Overview

Habit Mastery is an offline-first Flutter application for tracking habits, recording activity, reviewing progress, and receiving explainable next-step habit suggestions.

The application uses a local SQLite database for habit and activity records and SharedPreferences for user settings. Core features work without cloud services or network access.

## 2. Technology Stack

- **Flutter and Dart:** Application interface and application logic.
- **SQLite (`sqflite`):** Persistent storage for habits and activity entries.
- **SharedPreferences:** Storage for user preferences.
- **Flutter Test:** Automated unit, database, and widget testing.

## 3. Application Structure

```text
lib/
├── main.dart
└── data/
    ├── habit_database.dart
    └── habit_suggestion.dart

test/
├── database_test.dart
├── habit_crud_test.dart
├── habit_entry_test.dart
├── habit_filter_test.dart
├── habit_suggestion_test.dart
└── widget_test.dart
```

`main.dart` contains the application interface and screen-level interactions. The `data` directory separates database operations and suggestion logic from the main interface. The `test` directory contains automated tests for the application's major behaviors.

## 4. Screens and Responsibilities

### Dashboard and Habit Catalog
Displays habits and provides access to habit creation, editing, activation, deactivation, and deletion.

### Create and Edit Habit
Allows users to enter habit information and configure a target. Input validation prevents invalid habit names and invalid target values.

### Habit Detail and Activity
Displays habit information, allows activity entries to be recorded, presents activity history, and provides the Next-Step Habit Suggestion.

### History and Insights
Supports filtering activity by habit and reviewing progress summaries, including activity counts, totals, averages, and completion rates.

### Settings
Stores user preferences locally through SharedPreferences, including compact history display and the reminder preference.

## 5. Data Architecture

### Habit

The `Habit` table stores habit definitions. Its fields include:

- `id`
- `name`
- `category`
- `target_amount`
- `target_unit`
- `created_at`
- `is_active`

The habit name is required. Target values must be valid positive numbers when configured.

### HabitEntry

The `HabitEntry` table stores recorded activity associated with a habit. Its fields include:

- `id`
- `habit_id`
- `entry_date`
- `amount`
- `note`
- `completed`

The `habit_id` foreign key references the associated habit. Foreign-key enforcement and `ON DELETE CASCADE` maintain referential integrity when a habit is deleted.

### Persistence

The `HabitDatabase` data layer manages SQLite access and operations for creating, reading, updating, and deleting records. Activity amounts are validated before insertion.

SQLite stores habit and activity data locally so records remain available after the application closes and reopens.

SharedPreferences stores settings separately from the SQLite records.

## 6. Next-Step Habit Suggestion

The suggestion feature is implemented in `lib/data/habit_suggestion.dart`.

It uses a deterministic, local rule-based algorithm rather than a remote AI service or trained machine-learning model.

The algorithm:

1. Checks whether the current target is valid.
2. Retains the current target when there is insufficient activity history.
3. Excludes invalid activity amounts from the calculation.
4. Calculates the average of valid recent activity amounts.
5. Recommends a 10% target increase when the average meets or exceeds the current target.
6. Recommends a 10% target reduction when the average is below the current target.

The detail screen displays the recommendation and its explanation. The user can choose Apply or Not now. Applying a recommendation opens the existing habit editing flow; the recommendation is not saved until the user confirms through the normal save process.

The algorithm is intentionally simple and explainable. Its recommendations do not account for every factor affecting habit performance, and the user remains responsible for deciding whether a suggestion is appropriate.

See `AI_FEATURE.md` for the rules, reproducible evaluation cases, and limitations.

## 7. Application Data Flow

1. The user interacts with a screen.
2. The screen validates input where necessary.
3. Habit and activity operations are handled through the database layer.
4. SQLite persists the records.
5. Screens retrieve the relevant records and display updated information.
6. The suggestion logic evaluates the current target and recent activity when a recommendation is needed.
7. Settings are loaded from and saved to SharedPreferences.

## 8. Error Prevention and Data Integrity

The application uses input validation to prevent invalid habit targets and activity amounts. Destructive actions require confirmation where implemented. SQLite foreign keys maintain the relationship between habits and their activity entries, and cascading deletion prevents orphaned activity records.

The suggestion algorithm ignores invalid activity amounts when calculating its average and explains when a recommendation cannot be meaningfully calculated.

## 9. Testing

Automated tests cover database behavior, habit CRUD operations, activity entry operations, habit filtering, suggestion rules, and widget behavior.

The project is checked using:

```bash
flutter analyze
flutter test
```

Manual testing also checks the main user workflows, persistence after restarting the application, settings persistence, and suggestion interactions.

## 10. Limitations

- Data is stored locally; cloud synchronization is not provided.
- The suggestion algorithm is rule-based and does not learn from user behavior.
- The reminder preference does not itself enable operating-system notifications.
- Recommendations depend on the recorded activity data and may not explain why a user did or did not complete a habit.
