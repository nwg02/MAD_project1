
# Habit Mastery — Architecture

## 1. Overview

Habit Mastery is an offline-first Flutter application for tracking habits, recording activity, reviewing progress, and receiving explainable next-step habit suggestions.

The application uses SQLite for habit and activity records and SharedPreferences for user settings. Core features work without cloud services or network access.

## 2. Technology Stack

- **Flutter and Dart:** Application interface and application logic.
- **SQLite (`sqflite`):** Persistent storage for habits and activity entries.
- **SharedPreferences:** Persistent storage for user preferences.
- **Flutter Test:** Automated tests for application behavior.

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

`main.dart` contains the application interface, screen-level state, navigation, and user interactions. The `data` directory separates SQLite operations and recommendation logic from the interface. The `test` directory contains automated tests for major application behaviors.

## 4. Screens and Responsibilities

### Dashboard and Habit Catalog

Displays habits and provides access to habit creation, editing, activation, deactivation, and deletion.

### Create and Edit Habit

Allows users to enter habit information and configure a target. Input validation checks habit names and target values before saving.

### Habit Detail and Activity

Displays habit information, allows activity entries to be recorded, presents activity history, and provides the Next-Step Habit Suggestion.

### History and Insights

Supports filtering activity by habit and reviewing progress summaries, including activity counts, totals, averages, and completion rates.

### Settings

Stores user preferences through SharedPreferences, including compact history display and the reminder preference. The reminder preference does not itself enable operating-system notifications.

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

The habit name is required. Configured target values must be valid positive numbers.

### HabitEntry

The `HabitEntry` table stores activity associated with a habit. Its fields include:

- `id`
- `habit_id`
- `entry_date`
- `amount`
- `note`
- `completed`

The `habit_id` foreign key references the associated habit. Foreign-key enforcement and `ON DELETE CASCADE` maintain referential integrity when a habit is deleted.

### Persistence

The `HabitDatabase` data layer manages SQLite operations for creating, reading, updating, and deleting records. Activity amounts are validated before insertion.

SQLite stores habit and activity records locally so they remain available after the application closes and reopens.

SharedPreferences stores settings separately from SQLite records.

## 6. State Management and Lifecycle

The application uses Flutter's built-in state management through StatefulWidget state and `setState` for screen-level state changes. StatelessWidget is used where a widget does not need to manage its own mutable state.

Screen state holds information needed to render the current interface, such as loaded activity entries, selected filters, and temporary recommendation state. Persistent habit and activity records belong in SQLite, while display preferences belong in SharedPreferences.

Database reads and writes are asynchronous. After a successful change, the relevant screen reloads its data so displayed summaries reflect the stored records. Temporary interface state, such as dismissing a recommendation, is separate from persistent data.

This approach keeps the project straightforward for its current size. More complex shared state could be moved into a dedicated state-management solution if the application grows.

## 7. Next-Step Habit Suggestion

The suggestion feature is implemented in `lib/data/habit_suggestion.dart`.

It uses a deterministic, local rule-based algorithm rather than a remote AI service or trained machine-learning model.

The algorithm:

1. Checks whether the current target is valid.
2. Retains the current target when there is insufficient activity history.
3. Excludes invalid activity amounts from the calculation.
4. Calculates the average of valid recent activity amounts.
5. Recommends a 10% target increase when the average meets or exceeds the current target.
6. Recommends a 10% target reduction when the average is below the current target.

The detail screen displays the recommendation and its explanation. The user can choose Apply or Not now. Applying a recommendation opens the existing habit editing flow; the recommendation is not saved until the user confirms through the normal Save action.

The algorithm is intentionally simple and explainable. It does not account for every factor affecting habit performance, and the user remains responsible for deciding whether a suggestion is appropriate.

See `AI_FEATURE.md` for the rules, evaluation cases, and limitations.

## 8. Application Data Flow

1. The user interacts with a screen.
2. The screen validates input where necessary.
3. Habit and activity operations are handled by the database layer.
4. SQLite persists habit and activity records.
5. Screens retrieve relevant records and refresh their displayed information after changes.
6. The suggestion logic evaluates the current target and recent activity when a recommendation is needed.
7. Settings are loaded from and saved to SharedPreferences.

## 9. Error Prevention and Data Integrity

The application validates habit targets and activity amounts to prevent invalid values from being stored. Destructive actions require confirmation where implemented. SQLite foreign keys maintain the relationship between habits and their activity entries, and cascading deletion prevents orphaned activity records.

The suggestion algorithm excludes invalid activity amounts from its average and explains when a recommendation cannot meaningfully be calculated.

## 10. Testing

Automated tests cover database behavior, habit CRUD operations, activity entry operations, habit filtering, suggestion rules, and widget behavior.

Run the project checks from the project root:

```bash
flutter analyze
flutter test
```

Manual testing should verify the main user workflows, persistence after restarting the application, settings persistence, recommendation interactions, and offline operation. Record only results that have actually been observed.

## 11. Limitations

- Data is stored locally; cloud synchronization is not provided.
- The suggestion algorithm is rule-based and does not learn from user behavior.
- The reminder preference does not enable operating-system notifications.
- Recommendations depend on recorded activity and may not explain why activity was missed.
