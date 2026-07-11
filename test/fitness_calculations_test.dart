import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/utils/fitness_calculations.dart';

void main() {
  group('oneRepMax', () {
    test('returns measured weight for one repetition', () {
      expect(
        FitnessCalculations.oneRepMax(weight: 100, reps: 1),
        100,
      );
    });

    test('uses the Epley estimate for multiple repetitions', () {
      expect(
        FitnessCalculations.oneRepMax(weight: 100, reps: 10),
        closeTo(133.333, 0.001),
      );
    });

    test('rejects non-positive input', () {
      expect(FitnessCalculations.oneRepMax(weight: 0, reps: 10), 0);
      expect(FitnessCalculations.oneRepMax(weight: 100, reps: 0), 0);
    });
  });

  group('bmi', () {
    test('calculates BMI from kilograms and centimetres', () {
      expect(
        FitnessCalculations.bmi(weightKg: 70, heightCm: 175),
        closeTo(22.857, 0.001),
      );
    });

    test('rejects missing measurements', () {
      expect(FitnessCalculations.bmi(weightKg: 70, heightCm: 0), 0);
      expect(FitnessCalculations.bmi(weightKg: 0, heightCm: 175), 0);
    });
  });

  group('restSecondsRemaining', () {
    test('rounds partial display seconds up', () {
      final now = DateTime(2026, 7, 11, 12);
      final end = now.add(const Duration(milliseconds: 1501));

      expect(
        FitnessCalculations.restSecondsRemaining(endsAt: end, now: now),
        2,
      );
    });

    test('returns zero at and after the deadline', () {
      final end = DateTime(2026, 7, 11, 12);

      expect(
        FitnessCalculations.restSecondsRemaining(endsAt: end, now: end),
        0,
      );
      expect(
        FitnessCalculations.restSecondsRemaining(
          endsAt: end,
          now: end.add(const Duration(seconds: 10)),
        ),
        0,
      );
    });
  });
}
