
# Next-Step Habit Suggestion

## Overview

Habit Mastery includes a local, rule-based recommendation feature called Next-Step Habit Suggestion. It evaluates a habit's recent activity and suggests an adjustment to its target. The feature runs on the device and does not require an internet connection, cloud services, or remote AI inference.

The feature is intended to help users reflect on their progress. Recommendations are suggestions, not guarantees of improvement.

## Inputs

- The habit's current target amount.
- Up to five recent activity amounts, ordered from newest to oldest.
- The habit's target unit, used to display the recommendation.

## Recommendation Rules

1. If the current target is missing, invalid, or not positive, retain the supplied target and explain that a valid target is needed.
2. If there is no activity history, retain the current target and explain that there is insufficient history.
3. Exclude non-finite or negative activity amounts from the calculation.
4. If no valid activity amounts remain, retain the current target and explain that there is no valid activity data.
5. Otherwise, calculate the average of the valid recent activity amounts.
6. If the average meets or exceeds the current target, recommend increasing the target by 10%.
7. If the average is below the current target, recommend reducing the target by 10%.

## User Interaction and Control

The recommendation appears on the habit detail screen with an explanation. Users can choose **Apply** or **Not now**.

Apply opens the existing habit editing form with the proposed target prefilled. The recommendation is not saved automatically. The user must confirm through the normal Save action. Not now dismisses the suggestion for the current screen session.

This keeps the user in control of whether the target is changed.

## Reproducible Test Cases

The following cases document the expected behavior of the recommendation logic. Actual results should be confirmed by running the automated tests and manual checks described below.

| Case | Inputs | Expected Result | Actual Result |
|---|---|---|---|
| Normal recent history | Target 10; amounts 10, 12, 11 | Average is 11; recommend 11 | Automated test covers this scenario; confirm after running tests |
| No history | Target 10; no amounts | Retain target 10 and explain insufficient history | Automated test covers this scenario; confirm after running tests |
| Invalid target | Target 0; amounts 5, 6, 7 | Retain target 0 and explain the target is invalid | Automated test covers this scenario; confirm after running tests |
| Boundary and invalid values | Target 10; amounts NaN, infinity, 12, 14 | Ignore invalid values; average is 13; recommend 11 | Automated test covers this scenario; confirm after running tests |
| Counterexample | Target 10; amounts 0, 0, 0 | Recommend 9 even though lowering the target may not address why no activity was recorded | Automated test covers this scenario; confirm after running tests |

These cases cover normal recent history, missing data, invalid input, invalid activity values, and a counterexample to the recommendation rule.

## Baseline and Limitations

The baseline is the existing habit target without a recommendation. The feature compares recent activity with that target and applies a fixed 10% adjustment.

The baseline provides a simple reference point: the current target remains unchanged unless the user chooses to edit and save it. The recommendation offers a rule-based alternative using recent activity.

This is a simple heuristic, not a trained machine-learning model. It does not understand why activity changed, account for user circumstances, detect long-term trends, or establish whether a target is healthy or appropriate. Averages can be affected by unusual entries. In particular, repeated zero-value entries may cause the rule to recommend a lower target without explaining the underlying reason for inactivity.

Users should review recommendations and can decline them. The feature works locally and does not depend on remote inference.

## Evaluation Metrics and Sample Size

The initial evaluation uses five deterministic scenarios. These are software test cases, not a representative study of users.

The evaluation checks:

- **Recommendation correctness:** whether the returned target matches the defined rule.
- **Missing and invalid data handling:** whether the feature retains the current target and explains the problem when appropriate.
- **Explanation:** whether the user receives a reason for the recommendation or the lack of sufficient data.
- **User control:** whether the user can decline a suggestion and whether applying a suggestion requires normal form submission and saving.
- **Counterexample behavior:** whether the feature produces the documented result even when the rule may not address the underlying problem.

The sample size for this initial logic evaluation is five documented scenarios. The current evaluation does not establish that recommendations improve long-term habit completion. No user-study results or improvement rate are claimed.

## Verification

Automated tests are included for the recommendation logic, covering no history, activity averages at or above the target, averages below the target, invalid targets, invalid activity amounts, and a counterexample.

Before submission, run:

```bash
flutter analyze
flutter test
```

Record the actual results of these commands. Also manually verify that:

1. A recommendation appears on the habit detail screen.
2. Apply opens the edit form with the recommended target prefilled.
3. The target is not saved until the user confirms through Save.
4. Not now dismisses the suggestion for the current screen session.
5. The app continues to work with its local data when offline and after restarting.

Do not claim that a manual check passed unless it has been performed successfully.
