# Next-Step Habit Suggestion

## Overview

Habit Mastery includes a local, rule-based recommendation feature called Next-Step Habit Suggestion. It evaluates a habit's recent activity and suggests an adjustment to its target. The feature runs on the device and does not require an internet connection, cloud services, or remote AI inference.

The feature is intended to help users reflect on their progress. Its recommendations are suggestions, not guarantees of improvement.

## Inputs

- The habit's current target amount.
- Up to five recent activity amounts, ordered from newest to oldest.
- The habit's target unit, used to display the recommendation.

## Recommendation Rules

1. If the current target is missing, invalid, or not positive, the feature retains the supplied target and explains that a valid target is needed.
2. If there is no activity history, the feature retains the current target and explains that there is insufficient history.
3. Non-finite or negative activity amounts are excluded from the calculation.
4. If no valid activity amounts remain, the feature retains the current target and explains that there is no valid activity data.
5. Otherwise, the feature calculates the average of the valid recent activity amounts.
6. If the average meets or exceeds the current target, the feature recommends increasing the target by 10%.
7. If the average is below the current target, the feature recommends reducing the target by 10%.

## User Interaction

The recommendation appears on the habit detail screen with an explanation. Users can choose Apply or Not now.

Apply opens the existing habit editing form with the proposed target prefilled. The recommendation is not saved automatically. The user must confirm through the normal Save action. Not now dismisses the suggestion for the current screen session.

## Reproducible Test Cases

| Case | Inputs | Expected behavior |
|---|---|---|
| Normal recent history | Target 10; amounts 10, 12, 11 | Average is 11; recommend 11 |
| No history | Target 10; no amounts | Retain target 10 and explain insufficient history |
| Invalid target | Target 0; amounts 5, 6, 7 | Retain target 0 and explain the target is invalid |
| Boundary and invalid values | Target 10; amounts NaN, infinity, 12, 14 | Ignore invalid values; average is 13; recommend 11 |
| Counterexample | Target 10; amounts 0, 0, 0 | Recommend 9 under the current rule, even though a lower target may not address why no activity was recorded |

## Baseline and Limitations

The baseline is the existing habit target without a recommendation. The feature compares recent activity with that target and applies a fixed 10% adjustment.

This is a simple heuristic, not a trained machine-learning model. It does not understand why activity changed, account for user circumstances, detect long-term trends, or establish whether a target is healthy or appropriate. Averages can be affected by unusual entries. Users should review recommendations and can decline them.

## Verification

The recommendation logic is covered by automated tests for no history, average at or above the target, average below the target, invalid targets, and invalid activity amounts.

Record the actual results of `flutter analyze`, `flutter test`, and manual app testing before submission. Do not claim that a test passed unless it was run successfully.