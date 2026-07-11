class FitnessCalculations {
  const FitnessCalculations._();

  /// Epley estimate. One repetition is already the measured maximum.
  static double oneRepMax({required double weight, required double reps}) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  static double bmi({required double weightKg, required double heightCm}) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final heightMeters = heightCm / 100.0;
    return weightKg / (heightMeters * heightMeters);
  }

  /// Whole seconds remaining until [endsAt], rounded up for display.
  static int restSecondsRemaining({
    required DateTime endsAt,
    required DateTime now,
  }) {
    final milliseconds = endsAt.difference(now).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
  }
}
