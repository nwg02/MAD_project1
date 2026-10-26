
# Habit Mastery

Habit Mastery is an offline-first Flutter application for creating habits, tracking activity, and reviewing progress over time. It includes a local rule-based Next-Step Habit Suggestion feature to help users consider adjustments to their habit targets.

## Features

- Create, edit, activate, pause, and delete habits.
- Record, review, and delete activity entries.
- Store habits and activity entries locally using SQLite.
- Maintain the relationship between habits and entries with foreign keys and cascading deletion.
- Filter history by habit and review counts, totals, averages, completion rates, and progress summaries.
- Save display preferences using SharedPreferences.
- Receive explainable, rule-based habit target suggestions.
- Apply or dismiss suggestions while keeping the user in control of saving changes.
- Use the application offline.

## Technology Stack

- Flutter and Dart
- SQLite using `sqflite`
- SharedPreferences
- Material Design
- `sqflite_common_ffi` for database testing

## Getting Started

### Requirements

- Flutter SDK
- Dart SDK
- Android Studio or another supported Flutter development environment
- An Android emulator or compatible device for testing

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/nwg02/MAD_project1.git
   ```

2. Open the project directory:

   ```bash
   cd MAD_project1
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Check the code:

   ```bash
   flutter analyze
   ```

5. Run the automated tests:

   ```bash
   flutter test
   ```

6. Launch the application on a connected device or emulator:

   ```bash
   flutter run
   ```

## Project Structure

- `lib/main.dart` — application screens, navigation, forms, and user interactions.
- `lib/data/habit_database.dart` — local SQLite database operations and validation.
- `lib/data/habit_suggestion.dart` — rule-based habit target recommendation logic.
- `test/` — automated tests for database operations and habit suggestions.
- `AI_FEATURE.md` — recommendation rules, evaluation cases, baseline, and limitations.
- `ARCHITECTURE.md` — application architecture, state management, and data flow.

## Local Data and Privacy

Habit records and activity entries are stored locally in SQLite. User preferences are stored using SharedPreferences. The application does not require cloud storage, remote authentication, or remote AI inference to perform its core functions.

## Next-Step Habit Suggestion

The suggestion feature evaluates up to five recent activity amounts against the current target. It recommends a 10% increase when the recent average meets or exceeds the target, or a 10% decrease when the average falls below the target.

The recommendation is a simple heuristic, not a trained machine-learning model. Users can dismiss a recommendation or open the existing edit form and confirm changes themselves. See `AI_FEATURE.md` for the rules, test scenarios, and known limitations.

## Testing

Run the automated checks from the project root:

```bash
flutter analyze
flutter test
```

Before submission, also test the application on the required devices or emulators, verify that data persists after restarting the app, and verify that core functionality works offline.

## Project Documentation and Submission

The project submission should include the required project report, approved proposal, signed acknowledgment, architecture documentation, AI feature documentation, contribution evidence, presentation materials, questions document, and tested release APK as specified by the course assignment.

## Repository

GitHub: https://github.com/nwg02/MAD_project1
