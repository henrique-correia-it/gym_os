import '../data/models/user.dart';

class NutritionUtils {
  static double calculateTargetKcal(UserSettings user, double currentWeight) {
    double bmr = (user.gender == 'F')
        ? (10 * currentWeight) + (6.25 * user.height) - (5 * user.age) - 161
        : (10 * currentWeight) + (6.25 * user.height) - (5 * user.age) + 5;

    return (bmr * user.activityLevel) + user.caloricAdjustment;
  }
}
