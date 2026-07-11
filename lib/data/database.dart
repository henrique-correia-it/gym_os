import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import '../l10n/app_localizations.dart';
import '../utils/text_normalize.dart';
import 'models/nutrition.dart';
import 'models/workout.dart';
import 'models/user.dart';

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open(
      [
        FoodItemSchema,
        DayLogSchema,
        MealEntrySchema,
        UserSettingsSchema,
        WeightEntrySchema,
        WorkoutPlanSchema,
        WorkoutDaySchema,
        WorkoutExerciseSchema,
        ExerciseSetSchema, // <--- ADICIONADO AQUI
      ],
      directory: dir.path,
    );

    final count = await isar.foodItems.count();
    if (count == 0) {
      await importInitialData();
      await _createDefaultUser();
    } else {
      await _migrateSearchNames();
    }
  }

  Future<void> importInitialData() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/initial_food_data.json');
      final List<dynamic> data = json.decode(jsonString);

      final locale = ui.PlatformDispatcher.instance.locale;
      final l10n = lookupAppLocalizations(locale);

      final List<FoodItem> itemsToSave = [];

      for (var item in data) {
        final foodName = (item['n'] as String?) ?? l10n.unknown;
        final food = FoodItem()
          ..name = foodName
          ..searchName = normalizeForSearch(foodName)
          ..kcal = (item['k'] as num).toDouble()
          ..protein = (item['p'] as num).toDouble()
          ..carbs = (item['c'] as num).toDouble()
          ..fat = (item['f'] as num).toDouble()
          ..source = item['s'] ?? l10n.generalCategory
          ..isFavorite = (item['s'] == 'Meus Favoritos')
          ..unit = item['u'] ?? 'g';

        itemsToSave.add(food);
      }

      await isar.writeTxn(() async {
        await isar.foodItems.putAll(itemsToSave);
      });
    } catch (e) {
      debugPrint("Erro ao importar dados: $e");
    }
  }

  // Populates searchName for records created before this field existed.
  Future<void> _migrateSearchNames() async {
    final all = await isar.foodItems.where().findAll();
    final toUpdate = all.where((f) => f.searchName.isEmpty).toList();
    if (toUpdate.isEmpty) return;
    for (final f in toUpdate) {
      f.searchName = normalizeForSearch(f.name);
    }
    await isar.writeTxn(() async {
      await isar.foodItems.putAll(toUpdate);
    });
    debugPrint('GymOS migration: updated ${toUpdate.length} searchName fields');
  }

  Future<void> _createDefaultUser() async {
    final user = UserSettings()
      ..name = ""
      ..gender = "M"
      ..birthDate = null
      ..height = 0
      ..weight = 0
      ..activityLevel = 1.2
      ..caloricAdjustment = 0;

    await isar.writeTxn(() async {
      await isar.userSettings.put(user);
    });
  }

  // ===========================================================================
  // MÉTODOS DE BACKUP E RESTAURO ATUALIZADOS
  // ===========================================================================

  Future<String> createBackupJson() async {
    final foods = await isar.foodItems.where().exportJson();
    final logs = await isar.dayLogs.where().exportJson();
    final meals = await isar.mealEntrys.where().exportJson();
    final users = await isar.userSettings.where().exportJson();
    final weights = await isar.weightEntrys.where().exportJson();
    final plans = await isar.workoutPlans.where().exportJson();
    final days = await isar.workoutDays.where().exportJson();
    final exercises = await isar.workoutExercises.where().exportJson();

    // NOVO: Exportar Cargas
    final sets = await isar.exerciseSets.where().exportJson();

    final backupMap = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': 1,
      'data': {
        'foodItems': foods,
        'dayLogs': logs,
        'mealEntrys': meals,
        'userSettings': users,
        'weightEntrys': weights,
        'workoutPlans': plans,
        'workoutDays': days,
        'workoutExercises': exercises,
        'exerciseSets': sets, // <--- ADICIONADO AQUI
      }
    };

    return jsonEncode(backupMap);
  }

  Future<void> restoreBackupJson(String jsonString) async {
    try {
      final Map<String, dynamic> backup = jsonDecode(jsonString);
      final data = backup['data'] as Map<String, dynamic>;

      await isar.writeTxn(() async {
        await isar.clear();

        if (data['foodItems'] != null) {
          await isar.foodItems
              .importJson(List<Map<String, dynamic>>.from(data['foodItems']));
        }
        if (data['mealEntrys'] != null) {
          await isar.mealEntrys
              .importJson(List<Map<String, dynamic>>.from(data['mealEntrys']));
        }
        if (data['dayLogs'] != null) {
          await isar.dayLogs
              .importJson(List<Map<String, dynamic>>.from(data['dayLogs']));
        }
        if (data['userSettings'] != null) {
          await isar.userSettings.importJson(
              List<Map<String, dynamic>>.from(data['userSettings']));
        }
        if (data['weightEntrys'] != null) {
          await isar.weightEntrys.importJson(
              List<Map<String, dynamic>>.from(data['weightEntrys']));
        }
        if (data['workoutExercises'] != null) {
          await isar.workoutExercises.importJson(
              List<Map<String, dynamic>>.from(data['workoutExercises']));
        }
        if (data['workoutDays'] != null) {
          await isar.workoutDays
              .importJson(List<Map<String, dynamic>>.from(data['workoutDays']));
        }
        if (data['workoutPlans'] != null) {
          await isar.workoutPlans.importJson(
              List<Map<String, dynamic>>.from(data['workoutPlans']));
        }
        // NOVO: Importar Cargas
        if (data['exerciseSets'] != null) {
          await isar.exerciseSets.importJson(
              List<Map<String, dynamic>>.from(data['exerciseSets']));
        }
      });

      debugPrint("Backup restaurado com sucesso!");
    } catch (e) {
      final locale = ui.PlatformDispatcher.instance.locale;
      final l10n = lookupAppLocalizations(locale);
      debugPrint(l10n.fatalRestoreError(e.toString()));
      rethrow;
    }
  }
}
