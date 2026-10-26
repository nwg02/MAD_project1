
class HabitSuggestion {
  final double recommendedAmount;
  final String reason;

  const HabitSuggestion({
    required this.recommendedAmount,
    required this.reason,
  });
}

HabitSuggestion suggestNextTarget({
  required double currentTarget,
  required List<double> recentAmounts,
}) {
  if (!currentTarget.isFinite || currentTarget <= 0) {
    return HabitSuggestion(
      recommendedAmount: currentTarget,
      reason: 'The current target is invalid. Set a valid positive target first.',
    );
  }

  if (recentAmounts.isEmpty) {
    return HabitSuggestion(
      recommendedAmount: currentTarget,
      reason: 'There is not enough activity history to suggest a change.',
    );
  }

  final validAmounts = recentAmounts
      .where((amount) => amount.isFinite && amount >= 0)
      .toList();

  if (validAmounts.isEmpty) {
    return HabitSuggestion(
      recommendedAmount: currentTarget,
      reason: 'There are no valid recent activity amounts to evaluate.',
    );
  }

  final average =
      validAmounts.reduce((a, b) => a + b) / validAmounts.length;

  final recommendation = average >= currentTarget
      ? currentTarget * 1.1
      : currentTarget * 0.9;

  return HabitSuggestion(
    recommendedAmount: recommendation,
    reason: average >= currentTarget
        ? 'Your recent average meets or exceeds your target. Consider increasing it by 10%.'
        : 'Your recent average is below your target. Consider reducing it by 10%.',
  );
}
