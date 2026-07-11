import 'package:isar/isar.dart';

import 'package:gym_os/utils/text_normalize.dart';

part 'nutrition.g.dart';

@collection
class FoodItem {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String name;

  // Normalized (no accents, lowercase) version of name for accent-insensitive search.
  // Populated on every save; searched instead of `name` when filtering locally.
  String searchName = '';

  late double kcal;
  late double protein;
  late double carbs;
  late double fat;

  late String source;
  bool isFavorite = false;

  late String unit; // "g" ou "un"

  final ingredients = IsarLinks<MealEntry>();
  double portions = 1;

  // --- NOVO MÉTODO A ADICIONAR ---
  /// Cria uma cópia limpa de um item da API para ser salvo localmente.
  /// Garante que o ID é resetado e a source muda para "User".
  static FoodItem fromApi(FoodItem apiItem) {
    return FoodItem()
      ..name = apiItem.name
      ..searchName = normalizeForSearch(apiItem.name)
      ..kcal = apiItem.kcal
      ..protein = apiItem.protein
      ..carbs = apiItem.carbs
      ..fat = apiItem.fat
      ..unit = apiItem.unit
      ..source = "User"
      ..isFavorite = false
      ..portions = 1;
  }
}

@collection
class MealEntry {
  Id id = Isar.autoIncrement;

  late String foodName;
  late double amount;
  late String unit;

  late double baseKcal;
  late double baseProtein;
  late double baseCarbs;
  late double baseFat;

  late double kcal;
  late double protein;
  late double carbs;
  late double fat;

  late String type;

  // Explicit ordering within a meal group. Null on old records; treated as id*1.0.
  double? sortOrder;
}

@collection
class DayLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late DateTime date;
  double targetKcal = 0;
  double consumedKcal = 0;

  double? targetProtein;
  double? targetCarbs;
  double? targetFat;

  final meals = IsarLinks<MealEntry>();
}
