import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/models/nutrition.dart';
import '../data/models/user.dart';
import '../services/cloud_sync_service.dart';
import 'app_providers.dart'; // <--- Importante: É daqui que vem agora o selectedDateProvider
import '../utils/nutrition_utils.dart';

// REMOVIDO: final selectedDateProvider = ... (Já existe no app_providers.dart)

// O DailyLog depende da data selecionada (vinda do app_providers)
final dailyLogProvider = AsyncNotifierProvider<DailyLogNotifier, DayLog?>(() {
  return DailyLogNotifier();
});

class DailyLogNotifier extends AsyncNotifier<DayLog?> {
  @override
  Future<DayLog?> build() async {
    final db = ref.read(databaseProvider);
    // Agora usa o provider global do app_providers.dart
    final selectedDate = ref.watch(selectedDateProvider);
    final user = await db.isar.userSettings.where().findFirst();
    var dayLog =
        await db.isar.dayLogs.filter().dateEqualTo(selectedDate).findFirst();

    if (user == null) return null;

    if (dayLog == null) {
      double finalTarget =
          NutritionUtils.calculateTargetKcal(user, user.weight);
      double tKcal = finalTarget > 0 ? finalTarget : 2000;

      dayLog = DayLog()
        ..date = selectedDate
        ..targetKcal = tKcal
        ..consumedKcal = 0
        ..targetProtein = (tKcal * user.macroProtein) / 4.0
        ..targetCarbs = (tKcal * user.macroCarbs) / 4.0
        ..targetFat = (tKcal * user.macroFat) / 9.0;
    } else {
      await dayLog.meals.load();
      
      // Recalcula consumedKcal com base nas refeições carregadas
      double totalKcal = 0;
      for (var m in dayLog.meals) {
        totalKcal += m.kcal;
      }
      dayLog.consumedKcal = totalKcal;
      
      // Corrige targetKcal se estiver 0 (dados legados ou não inicializados)
      if (dayLog.targetKcal <= 0) {
        double finalTarget =
            NutritionUtils.calculateTargetKcal(user, user.weight);
        double tKcal = finalTarget > 0 ? finalTarget : 2000;
        
        dayLog.targetKcal = tKcal;
        dayLog.targetProtein = (tKcal * user.macroProtein) / 4.0;
        dayLog.targetCarbs = (tKcal * user.macroCarbs) / 4.0;
        dayLog.targetFat = (tKcal * user.macroFat) / 9.0;
        
        // Persiste a correção
        await ref.read(databaseProvider).isar.writeTxn(() async {
          await ref.read(databaseProvider).isar.dayLogs.put(dayLog!);
        });
      }
    }

    return dayLog;
  }

  Future<void> addMeal(FoodItem food, double amount, String mealType) async {
    final db = ref.read(databaseProvider);

    // 1. Usa o provider global
    final selectedDate = ref.read(selectedDateProvider);

    // 2. Buscar o Log diretamente à BD para essa data
    var targetLog =
        await db.isar.dayLogs.filter().dateEqualTo(selectedDate).findFirst();

    // 3. Se o log não existir na BD, CRIA-O AGORA.
    if (targetLog == null) {
      final user = await db.isar.userSettings.where().findFirst();
      double target = 2000;

      if (user != null) {
        target = NutritionUtils.calculateTargetKcal(user, user.weight);
      }

      targetLog = DayLog()
        ..date = selectedDate
        ..targetKcal = target
        ..consumedKcal = 0
        ..targetProtein = (target * (user?.macroProtein ?? 0.30)) / 4.0
        ..targetCarbs = (target * (user?.macroCarbs ?? 0.40)) / 4.0
        ..targetFat = (target * (user?.macroFat ?? 0.30)) / 9.0;

      await db.isar.writeTxn(() async {
        await db.isar.dayLogs.put(targetLog!);
      });
    }

    // 4. Calcular nutrição
    double ratio = (food.unit == 'un') ? amount : (amount / 100.0);
    final newMeal = MealEntry()
      ..foodName = food.name
      ..amount = amount
      ..type = mealType
      ..unit = food.unit
      ..baseKcal = food.kcal
      ..baseProtein = food.protein
      ..baseCarbs = food.carbs
      ..baseFat = food.fat
      ..kcal = food.kcal * ratio
      ..protein = food.protein * ratio
      ..carbs = food.carbs * ratio
      ..fat = food.fat * ratio;

    // 5. Transação Atómica
    await db.isar.writeTxn(() async {
      await db.isar.mealEntrys.put(newMeal);
      targetLog!.meals.add(newMeal);
      await targetLog.meals.save(); // Salva a lista primeiro

      // RECÁLCULO TOTAL AQUI:
      double totalKcal = 0;
      for (var m in targetLog.meals) {
        totalKcal += m.kcal;
      }
      targetLog.consumedKcal = totalKcal;

      await db.isar.dayLogs.put(targetLog);
    });
    CloudSyncService(db).syncDayLog(targetLog);

    // Força um refresh completo do provider para garantir que o header atualiza
    final _ = ref.refresh(dailyLogProvider);
  }

  Future<void> deleteMeal(MealEntry meal) async {
    final db = ref.read(databaseProvider);
    final currentLog = state.value;
    if (currentLog == null) return;

    await db.isar.writeTxn(() async {
      currentLog.meals.remove(meal);
      await db.isar.mealEntrys.delete(meal.id);
      await currentLog.meals.save();

      // RECÁLCULO TOTAL AQUI:
      double totalKcal = 0;
      for (var m in currentLog.meals) {
        totalKcal += m.kcal;
      }
      currentLog.consumedKcal = totalKcal;

      await db.isar.dayLogs.put(currentLog);
    });
    CloudSyncService(db).syncDayLog(currentLog);
    // Força um refresh completo do provider para garantir que o header atualiza
    final _ = ref.refresh(dailyLogProvider);
  }

  Future<void> updateMeal(
      MealEntry meal, double newAmount, String newType) async {
    final db = ref.read(databaseProvider);
    final currentLog = state.value;
    if (currentLog == null) return;

    await db.isar.writeTxn(() async {
      meal.amount = newAmount;
      meal.type = newType;
      double newRatio = (meal.unit == 'un') ? newAmount : (newAmount / 100.0);

      meal.kcal = meal.baseKcal * newRatio;
      meal.protein = meal.baseProtein * newRatio;
      meal.carbs = meal.baseCarbs * newRatio;
      meal.fat = meal.baseFat * newRatio;

      await db.isar.mealEntrys.put(meal);
      await currentLog.meals.save();

      // RECÁLCULO TOTAL AQUI (remove o currentLog.consumedKcal = currentLog...):
      double totalKcal = 0;
      for (var m in currentLog.meals) {
        totalKcal += m.kcal;
      }
      currentLog.consumedKcal = totalKcal;

      await db.isar.dayLogs.put(currentLog);
    });
    CloudSyncService(db).syncDayLog(currentLog);
    // Força um refresh completo do provider para garantir que o header atualiza
    final _ = ref.refresh(dailyLogProvider);
  }
}
