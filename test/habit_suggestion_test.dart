
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery/data/habit_suggestion.dart';

void main() {
  group('Next-Step Habit Suggestion', () {
    test('uses current target when there is no history', () {
      final result = suggestNextTarget(
        currentTarget: 10,
        recentAmounts: [],
      );

      expect(result.recommendedAmount, 10);
      expect(result.reason, contains('not enough'));
    });

    test('increases target when recent average meets target', () {
      final result = suggestNextTarget(
        currentTarget: 10,
        recentAmounts: [10, 12, 11],
      );

      expect(result.recommendedAmount, closeTo(11, 0.001));
    });

    test('reduces target when recent average is below target', () {
      final result = suggestNextTarget(
        currentTarget: 10,
        recentAmounts: [5, 6, 7],
      );

      expect(result.recommendedAmount, closeTo(9, 0.001));
    });

    test('keeps current target when target is invalid', () {
      final result = suggestNextTarget(
        currentTarget: 0,
        recentAmounts: [5, 6, 7],
      );

      expect(result.recommendedAmount, 0);
      expect(result.reason, contains('invalid'));
    });

    test('ignores invalid activity amounts', () {
      final result = suggestNextTarget(
        currentTarget: 10,
        recentAmounts: [double.nan, double.infinity, 12, 14],
      );

      expect(result.recommendedAmount, closeTo(11, 0.001));
    });
  });
}
