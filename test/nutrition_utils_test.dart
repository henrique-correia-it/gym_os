import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/data/models/user.dart';
import 'package:gym_os/utils/nutrition_utils.dart';

void main() {
  test('calculates the male calorie target with Mifflin-St Jeor', () {
    final user = UserSettings()
      ..gender = 'M'
      ..height = 175
      ..birthDate = null
      ..activityLevel = 1.2
      ..caloricAdjustment = 0;

    expect(NutritionUtils.calculateTargetKcal(user, 70), closeTo(2008.5, 0.01));
  });

  test('calculates the female calorie target with an adjustment', () {
    final user = UserSettings()
      ..gender = 'F'
      ..height = 175
      ..birthDate = null
      ..activityLevel = 1.2
      ..caloricAdjustment = -200;

    expect(NutritionUtils.calculateTargetKcal(user, 70), closeTo(1609.3, 0.01));
  });
}
