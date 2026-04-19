import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../l10n/app_localizations.dart';
import '../data/models/nutrition.dart';
import '../data/models/user.dart';
import '../utils/nutrition_utils.dart';
import 'app_providers.dart';

enum IMCStatus { underweight, normal, overweight, obese }

extension IMCStatusExtension on IMCStatus {
  String getLocalizedName(AppLocalizations l10n) {
    switch (this) {
      case IMCStatus.underweight:
        return l10n.imcUnderweight;
      case IMCStatus.normal:
        return l10n.imcNormal;
      case IMCStatus.overweight:
        return l10n.imcOverweight;
      case IMCStatus.obese:
        return l10n.imcObese;
    }
  }
}

class DashboardData {
  final double eatenKcal;
  final double targetKcal;

  final double eatenProtein;
  final double eatenCarbs;
  final double eatenFat;

  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  final double weight;
  final double height;
  final String userName;
  final List<MealEntry> meals;
  final bool isEditable;

  DashboardData({
    this.eatenKcal = 0,
    this.targetKcal = 2000,
    this.eatenProtein = 0,
    this.eatenCarbs = 0,
    this.eatenFat = 0,
    this.targetProtein = 150,
    this.targetCarbs = 200,
    this.targetFat = 60,
    this.weight = 0,
    this.height = 175,
    this.userName = "",
    this.meals = const [],
    this.isEditable = true,
  });

  double get progress =>
      (targetKcal > 0) ? (eatenKcal / targetKcal).clamp(0.0, 1.0) : 0;
  double get remainingKcal =>
      (targetKcal - eatenKcal).clamp(0, double.infinity);

  double get imc {
    if (height <= 0) return 0;
    double hMeters = height / 100.0;
    return weight / (hMeters * hMeters);
  }

  IMCStatus get imcStatus {
    if (imc < 18.5) return IMCStatus.underweight;
    if (imc < 24.9) return IMCStatus.normal;
    if (imc < 29.9) return IMCStatus.overweight;
    return IMCStatus.obese;
  }
}

final dashboardProvider = StreamProvider.autoDispose<DashboardData>((ref) {
  final db = ref.watch(databaseProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final currentLocale = ref.watch(localeProvider);
  final l10n = lookupAppLocalizations(currentLocale);

  final startOfDay = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
  final endOfDay = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59, 999);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final bool isEditable = !selectedDate.isBefore(yesterday);

  final controller = StreamController<void>();

  final logQuery = db.isar.dayLogs.filter().dateBetween(startOfDay, endOfDay,
      includeLower: true, includeUpper: true);

  // Escutar alterações nos diários
  final sub1 = logQuery.watch(fireImmediately: true).listen((_) {
    if (!controller.isClosed) controller.add(null);
  });

  // Escutar alterações nas refeições
  // Observação: Isar requer a observação da coleção inteira para links (MealEntry) pois não tem uma propriedade direta 'date'.
  // Esta query pode impactar performance se houverem milhares de refeições, no futuro 'date' pode ser adicionado ao model.
  final sub2 = db.isar.mealEntrys.watchLazy().listen((_) {
    if (!controller.isClosed) controller.add(null);
  });

  // Escutar alterações no perfil do utilizador
  final sub3 = db.isar.userSettings.where().watchLazy().listen((_) {
    if (!controller.isClosed) controller.add(null);
  });

  // Escutar alterações NA TABELA DE PESOS (Muito importante para atualizar em tempo real!)
  // Otimização de performance: só reage se o peso alterado for de hoje ou do passado.
  final sub4 = db.isar.weightEntrys
      .filter()
      .dateLessThan(endOfDay, include: true)
      .watchLazy()
      .listen((_) {
    if (!controller.isClosed) controller.add(null);
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    sub3.cancel();
    sub4.cancel();
    controller.close();
  });

  return controller.stream.asyncMap((_) async {
    final user =
        await db.isar.userSettings.where().findFirst() ?? UserSettings();
    final log = await logQuery.findFirst();

    // ---------------------------------------------------------
    // A MAGIA DO CÁLCULO DE PESO BLINDADO
    // ---------------------------------------------------------

    // Limite: Final exato do dia selecionado
    final limitDate = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    // 1. Procuramos o último peso registado ANTES OU NO PRÓPRIO DIA selecionado
    var targetWeightEntry = await db.isar.weightEntrys
        .filter()
        .dateLessThan(limitDate, include: true)
        .sortByDateDesc()
        .findFirst();

    // 2. Se for nulo (ou seja, é um dia antes do teu primeiro registo de sempre),
    // vamos buscar o PRIMEIRO PESO DE SEMPRE, em vez de ir buscar o teu peso atual de 84kg.
    targetWeightEntry ??=
        await db.isar.weightEntrys.where().sortByDate().findFirst();

    // 3. O peso real para a interface (só usa o perfil se a app estiver sem dados nenhuns)
    final realWeight = targetWeightEntry?.weight ?? user.weight;

    // ---------------------------------------------------------
    // CÁLCULO DA META BASE (A tua meta real consoante o peso histórico)
    // ---------------------------------------------------------

    // Para dias passados: usar TDEE sem ajuste, para que alterações futuras ao
    // ajuste calórico não alterem retroativamente os dados históricos.
    final isPastDay = selectedDate.isBefore(today);
    double defaultTarget = 2000.0;

    // Só calcula dinamicamente se o utilizador já inseriu um perfil real.
    // Baseamo-nos no user.name ser diferente do default ou noutras variáveis preenchidas
    if (user.name != "Utilizador" || user.birthDate != null) {
      double calculatedTarget =
          NutritionUtils.calculateTargetKcal(user, realWeight);

      if (calculatedTarget > 0) {
        defaultTarget = isPastDay
            ? (calculatedTarget - user.caloricAdjustment).clamp(500.0, 10000.0)
            : calculatedTarget;
      }
    }

    // ---------------------------------------------------------

    double eatenKcal = 0;
    double p = 0, c = 0, f = 0;

    // A meta por defeito passa a ser logo o cálculo correto!
    double finalTargetKcal = defaultTarget;
    List<MealEntry> mealList = [];

    if (log != null) {
      await log.meals.load();
      mealList = log.meals.toList();
      mealList.sort((a, b) {
        final aKey = a.sortOrder ?? a.id.toDouble();
        final bKey = b.sortOrder ?? b.id.toDouble();
        return aKey.compareTo(bKey);
      });

      for (var meal in mealList) {
        eatenKcal += meal
            .kcal; // <-- ADICIONA ESTA LINHA: Soma as calorias reais da refeição
        p += meal.protein;
        c += meal.carbs;
        f += meal.fat;
      }

      p = double.parse(p.toStringAsFixed(1));
      c = double.parse(c.toStringAsFixed(1));
      f = double.parse(f.toStringAsFixed(1));
      // eatenKcal = (p * 4) + (c * 4) + (f * 9); // <-- REMOVE ESTA LINHA

      // Se este dia já tem um diário com uma meta gravada, usamos essa
      if (log.targetKcal > 0) {
        finalTargetKcal = log.targetKcal;
      }
    } else {
      // Se não há log (ex: Amanhã), procuramos o log de HOJE para ver se o alteraste manualmente
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final todayLog = await db.isar.dayLogs
          .filter()
          .dateBetween(todayStart, todayEnd)
          .findFirst();

      if (todayLog != null && todayLog.targetKcal > 0) {
        // Se hoje tens uma meta específica gravada, amanhã herda essa meta
        finalTargetKcal = todayLog.targetKcal;
      }
      // Se hoje também não tiver meta, ele mantém o 'defaultTarget' que calculámos lá em cima!
    }

    // O resto continua igual...
    double tProtein =
        log?.targetProtein ?? ((finalTargetKcal * user.macroProtein) / 4.0);
    double tCarbs =
        log?.targetCarbs ?? ((finalTargetKcal * user.macroCarbs) / 4.0);
    double tFat = log?.targetFat ?? ((finalTargetKcal * user.macroFat) / 9.0);

    return DashboardData(
      userName: (user.name.isEmpty || user.name == "Utilizador")
          ? l10n.defaultUserNameAthlete
          : user.name,
      weight: realWeight, // Variável isolada corretamente!
      height: user.height,
      targetKcal: finalTargetKcal,
      eatenKcal: eatenKcal,
      eatenProtein: p,
      eatenCarbs: c,
      eatenFat: f,
      targetProtein: tProtein,
      targetCarbs: tCarbs,
      targetFat: tFat,
      meals: mealList,
      isEditable: isEditable,
    );
  });
});
