import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../data/database.dart';
import '../data/models/nutrition.dart';
import '../data/models/workout.dart';
import '../data/models/user.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db;

  CloudSyncService(this._db);

  // ── Cache de autoSync (evita leitura Isar em cada chamada) ────────────────
  static bool? _autoSyncCache;
  static DateTime? _autoSyncCacheAt;

  // ── Debounce timers estáticos (persistem entre instâncias) ────────────────
  static final Map<String, Timer> _dayLogTimers = {};
  static final Map<String, DatabaseService> _dayLogDbFor = {};
  static Timer? _settingsTimer;
  static DatabaseService? _settingsDb;

  // ===========================================================================
  // 1. BACKUP TOTAL (manual, botão em Settings)
  // ===========================================================================
  Future<bool> backupToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      debugPrint('A iniciar backup total para a nuvem...');

      final isar = _db.isar;
      WriteBatch batch = _firestore.batch();
      int operationCount = 0;

      Future<void> commitBatchIfNeeded() async {
        if (operationCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // --- 1. DEFINIÇÕES DO PERFIL ---
      final userSettings = await isar.userSettings.where().findFirst();
      if (userSettings != null) {
        batch.set(userRef.collection('userSettings').doc('profile'), {
          'name': userSettings.name,
          'gender': userSettings.gender,
          'birthDate': userSettings.birthDate?.toIso8601String(),
          'weight': userSettings.weight,
          'height': userSettings.height,
          'activityLevel': userSettings.activityLevel,
          'goal': userSettings.goal,
          'macroProtein': userSettings.macroProtein,
          'macroCarbs': userSettings.macroCarbs,
          'macroFat': userSettings.macroFat,
          'caloricAdjustment': userSettings.caloricAdjustment,
          'avatarPath': userSettings.avatarPath,
          'themePersistence': userSettings.themePersistence,
          'language': userSettings.language,
          'autoSync': userSettings.autoSync,
          'hiddenGlobalFoods': userSettings.hiddenGlobalFoods,
          'customMealOrder': userSettings.customMealOrder,
        });
        operationCount++;
      }

      // --- 2. ALIMENTOS ---
      final foods = await isar.foodItems.where().findAll();
      for (var food in foods) {
        // Ignora os alimentos base do JSON no backup
        if (food.source == 'Geral') continue;
        await food.ingredients.load();

        final ingredientsList = food.ingredients
            .map((i) => {
                  'foodName': i.foodName,
                  'amount': i.amount,
                  'unit': i.unit,
                  'baseKcal': i.baseKcal,
                  'baseProtein': i.baseProtein,
                  'baseCarbs': i.baseCarbs,
                  'baseFat': i.baseFat,
                  'kcal': i.kcal,
                  'protein': i.protein,
                  'carbs': i.carbs,
                  'fat': i.fat,
                  'type': i.type,
                })
            .toList();

        batch.set(userRef.collection('foodItems').doc(food.id.toString()), {
          'name': food.name,
          'kcal': food.kcal,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
          'source': food.source,
          'isFavorite': food.isFavorite,
          'unit': food.unit,
          'portions': food.portions,
          'ingredients': ingredientsList,
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 3. HISTÓRICO DE PESO ---
      final weights = await isar.weightEntrys.where().findAll();
      for (var w in weights) {
        batch.set(userRef.collection('weightEntrys').doc(w.id.toString()), {
          'date': w.date.toIso8601String(),
          'weight': w.weight,
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 4. CARGAS (ExerciseSets) ---
      final sets = await isar.exerciseSets.where().findAll();
      for (var s in sets) {
        batch.set(userRef.collection('exerciseSets').doc(s.id.toString()), {
          'exerciseName': s.exerciseName,
          'weight': s.weight,
          'reps': s.reps,
          'date': s.date.toIso8601String(),
          'sessionId': s.sessionId,
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 5. REGISTOS DIÁRIOS ---
      final days = await isar.dayLogs.where().findAll();
      for (var day in days) {
        await day.meals.load();

        final mealsList = day.meals
            .map((m) => {
                  'foodName': m.foodName,
                  'amount': m.amount,
                  'unit': m.unit,
                  'baseKcal': m.baseKcal,
                  'baseProtein': m.baseProtein,
                  'baseCarbs': m.baseCarbs,
                  'baseFat': m.baseFat,
                  'kcal': m.kcal,
                  'protein': m.protein,
                  'carbs': m.carbs,
                  'fat': m.fat,
                  'type': m.type,
                  'sortOrder': m.sortOrder,
                })
            .toList();

        final docId = day.date.toIso8601String().split('T')[0];
        batch.set(userRef.collection('dayLogs').doc(docId), {
          'date': day.date.toIso8601String(),
          'targetKcal': day.targetKcal,
          'consumedKcal': day.consumedKcal,
          'targetProtein': day.targetProtein,
          'targetCarbs': day.targetCarbs,
          'targetFat': day.targetFat,
          'meals': mealsList,
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 6. PLANOS DE TREINO ---
      final plans = await isar.workoutPlans.where().findAll();
      for (var plan in plans) {
        await plan.days.load();

        final daysList = <Map<String, dynamic>>[];
        for (var d in plan.days) {
          await d.exercises.load();

          final exercisesList = d.exercises
              .map((e) => {
                    'name': e.name,
                    'sets': e.sets,
                    'reps': e.reps,
                    'weight': e.weight,
                    'notes': e.notes,
                  })
              .toList();

          daysList.add({'name': d.name, 'exercises': exercisesList});
        }

        batch.set(userRef.collection('workoutPlans').doc(plan.id.toString()), {
          'name': plan.name,
          'lastUpdated': plan.lastUpdated.toIso8601String(),
          'days': daysList,
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 7. FINALIZAR ---
      batch.set(
          userRef,
          {
            'lastSync': FieldValue.serverTimestamp(),
            'email': user.email,
            'migrated': true,
          },
          SetOptions(merge: true));

      await batch.commit();
      debugPrint('Backup total concluído com sucesso!');
      return true;
    } catch (e) {
      debugPrint('Erro fatal no backup para a nuvem: $e');
      return false;
    }
  }

  // ===========================================================================
  // 2. SYNC GRANULAR — só envia a entidade que mudou (1-2 writes no Firestore)
  // ===========================================================================

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  /// Verifica se o auto-sync está ativo — resultado em cache por 60s
  Future<bool> isAutoSyncEnabled() async {
    final now = DateTime.now();
    if (_autoSyncCache != null &&
        _autoSyncCacheAt != null &&
        now.difference(_autoSyncCacheAt!).inSeconds < 60) {
      return _autoSyncCache!;
    }
    final s = await _db.isar.userSettings.where().findFirst();
    _autoSyncCache = s?.autoSync ?? true;
    _autoSyncCacheAt = now;
    return _autoSyncCache!;
  }

  /// Invalida o cache de autoSync (chamar quando o utilizador altera a definição)
  static void invalidateAutoSyncCache() {
    _autoSyncCache = null;
    _autoSyncCacheAt = null;
  }

  /// Sincroniza as definições do utilizador, com debounce de 1s (force ignora debounce e cache)
  Future<void> syncUserSettings({bool force = false}) async {
    if (force) {
      invalidateAutoSyncCache();
      await _flushUserSettings();
      return;
    }
    if (!(await isAutoSyncEnabled())) return;
    _settingsDb = _db;
    _settingsTimer?.cancel();
    _settingsTimer = Timer(const Duration(milliseconds: 1000), () {
      _settingsTimer = null;
      final db = _settingsDb;
      if (db != null) CloudSyncService(db)._flushUserSettings();
    });
  }

  Future<void> _flushUserSettings() async {
    final user = _auth.currentUser;
    final userRef = _userDocRef();
    if (userRef == null || user == null) return;
    try {
      final s = await _db.isar.userSettings.where().findFirst();
      if (s == null) return;

      // Garante que o documento raiz existe (necessário para o login detectar conta existente)
      await userRef.set({
        'lastSync': FieldValue.serverTimestamp(),
        'email': user.email,
      }, SetOptions(merge: true));

      await userRef.collection('userSettings').doc('profile').set({
        'name': s.name,
        'gender': s.gender,
        'birthDate': s.birthDate?.toIso8601String(),
        'weight': s.weight,
        'height': s.height,
        'activityLevel': s.activityLevel,
        'goal': s.goal,
        'macroProtein': s.macroProtein,
        'macroCarbs': s.macroCarbs,
        'macroFat': s.macroFat,
        'caloricAdjustment': s.caloricAdjustment,
        'avatarPath': s.avatarPath,
        'themePersistence': s.themePersistence,
        'language': s.language,
        'autoSync': s.autoSync,
        'hiddenGlobalFoods': s.hiddenGlobalFoods,
        'customMealOrder': s.customMealOrder,
      });
      debugPrint('[Sync] userSettings OK');
    } catch (e) {
      debugPrint('[Sync] erro userSettings: $e');
    }
  }

  /// Sincroniza um alimento (e os seus ingredientes se for marmita)
  Future<void> syncFood(FoodItem food) async {
    if (!(await isAutoSyncEnabled())) return; // <-- BARREIRA ADICIONADA
    // NOVA PROTEÇÃO: Nunca sincroniza alimentos do JSON
    if (food.source == 'Geral') return;

    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      final freshFood = await _db.isar.foodItems.get(food.id) ?? food;
      await freshFood.ingredients.load();

      final ingredientsList = freshFood.ingredients
          .map((i) => {
                'foodName': i.foodName,
                'amount': i.amount,
                'unit': i.unit,
                'baseKcal': i.baseKcal,
                'baseProtein': i.baseProtein,
                'baseCarbs': i.baseCarbs,
                'baseFat': i.baseFat,
                'kcal': i.kcal,
                'protein': i.protein,
                'carbs': i.carbs,
                'fat': i.fat,
                'type': i.type,
              })
          .toList();
      await userRef.collection('foodItems').doc(freshFood.id.toString()).set({
        'name': freshFood.name,
        'kcal': freshFood.kcal,
        'protein': freshFood.protein,
        'carbs': freshFood.carbs,
        'fat': freshFood.fat,
        'source': freshFood.source,
        'isFavorite': freshFood.isFavorite,
        'unit': freshFood.unit,
        'portions': freshFood.portions,
        'ingredients': ingredientsList,
      });
      debugPrint(
          '[Sync] food "${freshFood.name}" OK (${ingredientsList.length} ingredientes)');
    } catch (e) {
      debugPrint('[Sync] erro food: $e');
    }
  }

  /// Sincroniza um registo diário com debounce de 1.2s — agrupa edições rápidas
  Future<void> syncDayLog(DayLog day) async {
    if (!(await isAutoSyncEnabled())) return;
    if (_userDocRef() == null) return;

    final docId = day.date.toIso8601String().split('T')[0];
    _dayLogDbFor[docId] = _db;
    _dayLogTimers[docId]?.cancel();
    _dayLogTimers[docId] = Timer(const Duration(milliseconds: 1200), () {
      _dayLogTimers.remove(docId);
      final db = _dayLogDbFor.remove(docId);
      if (db != null) CloudSyncService(db)._flushDayLog(docId);
    });
  }

  Future<void> _flushDayLog(String docId) async {
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      final date = DateTime.parse(docId);
      final freshDay = await _db.isar.dayLogs
          .filter()
          .dateBetween(date, DateTime(date.year, date.month, date.day, 23, 59, 59))
          .findFirst();
      if (freshDay == null) return;
      await freshDay.meals.load();

      final mealsList = freshDay.meals
          .map((m) => {
                'foodName': m.foodName,
                'amount': m.amount,
                'unit': m.unit,
                'baseKcal': m.baseKcal,
                'baseProtein': m.baseProtein,
                'baseCarbs': m.baseCarbs,
                'baseFat': m.baseFat,
                'kcal': m.kcal,
                'protein': m.protein,
                'carbs': m.carbs,
                'fat': m.fat,
                'type': m.type,
                'sortOrder': m.sortOrder,
              })
          .toList();
      await userRef.collection('dayLogs').doc(docId).set({
        'date': freshDay.date.toIso8601String(),
        'targetKcal': freshDay.targetKcal,
        'consumedKcal': freshDay.consumedKcal,
        'targetProtein': freshDay.targetProtein,
        'targetCarbs': freshDay.targetCarbs,
        'targetFat': freshDay.targetFat,
        'meals': mealsList,
      });
      debugPrint('[Sync] dayLog $docId OK (${mealsList.length} refeições)');
    } catch (e) {
      debugPrint('[Sync] erro dayLog: $e');
    }
  }

  /// Sincroniza um registo de peso isolado para a Nuvem
  Future<void> syncWeightEntry(WeightEntry w) async {
    if (!(await isAutoSyncEnabled())) return;
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      await userRef.collection('weightEntrys').doc(w.id.toString()).set({
        'date': w.date.toIso8601String(),
        'weight': w.weight,
      });
      debugPrint('[Sync] weightEntry ${w.id} OK');
    } catch (e) {
      debugPrint('[Sync] erro weightEntry: $e');
    }
  }

  /// Apaga um registo de peso isolado da Nuvem
  Future<void> deleteWeightEntry(int id) async {
    if (!(await isAutoSyncEnabled())) return;
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      await userRef.collection('weightEntrys').doc(id.toString()).delete();
      debugPrint('[Sync] deleteWeightEntry $id OK');
    } catch (e) {
      debugPrint('[Sync] erro deleteWeightEntry: $e');
    }
  }

  /// Sincroniza um registo de carga/série
  Future<void> syncExerciseSet(ExerciseSet s) async {
    if (!(await isAutoSyncEnabled())) return; // <-- BARREIRA ADICIONADA
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      await userRef.collection('exerciseSets').doc(s.id.toString()).set({
        'exerciseName': s.exerciseName,
        'weight': s.weight,
        'reps': s.reps,
        'date': s.date.toIso8601String(),
        'sessionId': s.sessionId,
      });
      debugPrint('[Sync] exerciseSet ${s.id} OK');
    } catch (e) {
      debugPrint('[Sync] erro exerciseSet: $e');
    }
  }

  /// Apaga um registo de carga da nuvem
  Future<void> deleteExerciseSet(int id) async {
    if (!(await isAutoSyncEnabled())) return; // <-- BARREIRA ADICIONADA
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      await userRef.collection('exerciseSets').doc(id.toString()).delete();
      debugPrint('[Sync] deleteExerciseSet $id OK');
    } catch (e) {
      debugPrint('[Sync] erro deleteExerciseSet: $e');
    }
  }

  /// Sincroniza um plano de treino completo
  Future<void> syncWorkoutPlan(WorkoutPlan plan) async {
    if (!(await isAutoSyncEnabled())) return; // <-- BARREIRA ADICIONADA
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      await plan.days.load();
      final daysList = <Map<String, dynamic>>[];
      for (var d in plan.days) {
        await d.exercises.load();
        final exercisesList = d.exercises
            .map((e) => {
                  'name': e.name,
                  'sets': e.sets,
                  'reps': e.reps,
                  'weight': e.weight,
                  'notes': e.notes,
                })
            .toList();
        daysList.add({'name': d.name, 'exercises': exercisesList});
      }
      await userRef.collection('workoutPlans').doc(plan.id.toString()).set({
        'name': plan.name,
        'lastUpdated': plan.lastUpdated.toIso8601String(),
        'days': daysList,
      });
      debugPrint('[Sync] workoutPlan "${plan.name}" OK');
    } catch (e) {
      debugPrint('[Sync] erro workoutPlan: $e');
    }
  }

  /// Apaga um plano de treino da nuvem
  Future<void> deleteWorkoutPlan(int id) async {
    if (!(await isAutoSyncEnabled())) return; // <-- BARREIRA ADICIONADA
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      await userRef.collection('workoutPlans').doc(id.toString()).delete();
      debugPrint('[Sync] deleteWorkoutPlan $id OK');
    } catch (e) {
      debugPrint('[Sync] erro deleteWorkoutPlan: $e');
    }
  }

  /// Apaga um alimento da nuvem
  Future<void> deleteFood(int id) async {
    if (!(await isAutoSyncEnabled())) return; // <-- BARREIRA ADICIONADA
    final userRef = _userDocRef();
    if (userRef == null) return;
    try {
      await userRef.collection('foodItems').doc(id.toString()).delete();
      debugPrint('[Sync] deleteFood $id OK');
    } catch (e) {
      debugPrint('[Sync] erro deleteFood: $e');
    }
  }

  // ===========================================================================
  // 3. RESTAURO OTIMIZADO (PARALELO E COM FILTRO GLOBAL)
  // ===========================================================================
  Future<bool> restoreFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userRef = _firestore.collection('users').doc(user.uid);
    final isar = _db.isar;

    try {
      debugPrint('A iniciar restauro paralelo da nuvem...');

      final userDoc = await userRef.get();
      if (!userDoc.exists) return false;

      // 1. FAZER TODOS OS DOWNLOADS EM PARALELO
      final results = await Future.wait([
        userRef.collection('userSettings').doc('profile').get(),
        userRef.collection('foodItems').get(),
        userRef.collection('dayLogs').get(),
        userRef.collection('weightEntrys').get(),
        userRef.collection('exerciseSets').get(),
        userRef.collection('workoutPlans').get(),
      ]);

      final profileDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final foodsQuery = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final daysQuery = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final weightsQuery = results[3] as QuerySnapshot<Map<String, dynamic>>;
      final setsQuery = results[4] as QuerySnapshot<Map<String, dynamic>>;
      final plansQuery = results[5] as QuerySnapshot<Map<String, dynamic>>;

      // Limpa a BD local
      await isar.writeTxn(() async {
        await isar.clear();
      });

      // IMPORTA O JSON DE BASE
      try {
        await _db.importInitialData();
      } catch (e) {
        debugPrint('Erro ao importar JSON inicial: $e');
      }

      // 2. GRAVAR DADOS DA CLOUD LOCALMENTE
      await isar.writeTxn(() async {
        List<String> hiddenFoods = [];

        // --- 1. RESTAURAR DEFINIÇÕES ---
        if (profileDoc.exists) {
          final data = profileDoc.data()!;
          final userSettings = UserSettings()
            ..uid = user.uid
            ..name = data['name'] ?? 'Utilizador'
            ..gender = data['gender'] ?? 'M'
            ..birthDate = data['birthDate'] != null
                ? DateTime.parse(data['birthDate'])
                : null
            ..weight = (data['weight'] ?? 70.0).toDouble()
            ..height = (data['height'] ?? 175.0).toDouble()
            ..activityLevel = (data['activityLevel'] ?? 1.2).toDouble()
            ..goal = data['goal'] ?? 'manter'
            ..macroProtein = (data['macroProtein'] ?? 0.30).toDouble()
            ..macroCarbs = (data['macroCarbs'] ?? 0.40).toDouble()
            ..macroFat = (data['macroFat'] ?? 0.30).toDouble()
            ..caloricAdjustment = (data['caloricAdjustment'] ?? 0.0).toDouble()
            ..avatarPath = data['avatarPath']
            ..themePersistence = data['themePersistence'] ?? 'system'
            ..language = data['language'] ?? 'pt'
            ..autoSync = data['autoSync'] ?? true
            ..hiddenGlobalFoods =
                List<String>.from(data['hiddenGlobalFoods'] ?? [])
            ..customMealOrder =
                List<String>.from(data['customMealOrder'] ?? []);

          hiddenFoods = userSettings.hiddenGlobalFoods;
          await isar.userSettings.put(userSettings);
        }

        // --- 1.5. APAGAR OS ALIMENTOS DO JSON QUE O USER OCULTOU ---
        if (hiddenFoods.isNotEmpty) {
          for (String hiddenName in hiddenFoods) {
            final foodToDelete = await isar.foodItems
                .filter()
                .nameEqualTo(hiddenName)
                .findFirst();
            if (foodToDelete != null) {
              await isar.foodItems.delete(foodToDelete.id);
            }
          }
        }

        // --- 2. RESTAURAR ALIMENTOS PERSONALIZADOS (AGORA MANTÉM O ID!) ---
        for (var doc in foodsQuery.docs) {
          final data = doc.data();
          final food = FoodItem()
            ..id = int.tryParse(doc.id) ??
                Isar.autoIncrement // <--- CORREÇÃO CRÍTICA AQUI
            ..name = data['name']
            ..kcal = (data['kcal']).toDouble()
            ..protein = (data['protein']).toDouble()
            ..carbs = (data['carbs']).toDouble()
            ..fat = (data['fat']).toDouble()
            ..source = data['source']
            ..isFavorite = data['isFavorite'] ?? false
            ..unit = data['unit'] ?? 'g'
            ..portions = (data['portions'] ?? 1.0).toDouble();

          await isar.foodItems.put(food);

          if (data['ingredients'] != null) {
            for (var ingData in data['ingredients']) {
              final mealEntry = MealEntry()
                ..foodName = ingData['foodName']
                ..amount = (ingData['amount']).toDouble()
                ..unit = ingData['unit']
                ..baseKcal = (ingData['baseKcal']).toDouble()
                ..baseProtein = (ingData['baseProtein']).toDouble()
                ..baseCarbs = (ingData['baseCarbs']).toDouble()
                ..baseFat = (ingData['baseFat']).toDouble()
                ..kcal = (ingData['kcal']).toDouble()
                ..protein = (ingData['protein']).toDouble()
                ..carbs = (ingData['carbs']).toDouble()
                ..fat = (ingData['fat']).toDouble()
                ..type = ingData['type'] ?? '';

              await isar.mealEntrys.put(mealEntry);
              food.ingredients.add(mealEntry);
            }
            await food.ingredients.save();
          }
        }

        // --- 3. RESTAURAR REGISTOS DIÁRIOS ---
        for (var doc in daysQuery.docs) {
          final data = doc.data();
          final dayLog = DayLog()
            // DayLogs não precisam de forçar ID porque o Firebase usa a data como ID
            ..date = DateTime.parse(data['date'])
            ..targetKcal = (data['targetKcal']).toDouble()
            ..consumedKcal = (data['consumedKcal']).toDouble()
            ..targetProtein = data['targetProtein'] != null
                ? (data['targetProtein']).toDouble()
                : null
            ..targetCarbs = data['targetCarbs'] != null
                ? (data['targetCarbs']).toDouble()
                : null
            ..targetFat = data['targetFat'] != null
                ? (data['targetFat']).toDouble()
                : null;

          await isar.dayLogs.put(dayLog);

          if (data['meals'] != null) {
            for (var mData in data['meals']) {
              final mealEntry = MealEntry()
                ..foodName = mData['foodName']
                ..amount = (mData['amount']).toDouble()
                ..unit = mData['unit']
                ..baseKcal = (mData['baseKcal']).toDouble()
                ..baseProtein = (mData['baseProtein']).toDouble()
                ..baseCarbs = (mData['baseCarbs']).toDouble()
                ..baseFat = (mData['baseFat']).toDouble()
                ..kcal = (mData['kcal']).toDouble()
                ..protein = (mData['protein']).toDouble()
                ..carbs = (mData['carbs']).toDouble()
                ..fat = (mData['fat']).toDouble()
                ..type = mData['type'] ?? ''
                ..sortOrder = (mData['sortOrder'] as num?)?.toDouble();

              await isar.mealEntrys.put(mealEntry);
              dayLog.meals.add(mealEntry);
            }
            await dayLog.meals.save();
          }
        }

        // --- 4. PESOS (AGORA MANTÉM O ID!) ---
        for (var doc in weightsQuery.docs) {
          final data = doc.data();
          final w = WeightEntry()
            ..id =
                int.tryParse(doc.id) ?? Isar.autoIncrement // <--- CORREÇÃO AQUI
            ..date = DateTime.parse(data['date'])
            ..weight = (data['weight']).toDouble();
          await isar.weightEntrys.put(w);
        }

        // --- 5. CARGAS (AGORA MANTÉM O ID!) ---
        for (var doc in setsQuery.docs) {
          final data = doc.data();
          final s = ExerciseSet()
            ..id =
                int.tryParse(doc.id) ?? Isar.autoIncrement // <--- CORREÇÃO AQUI
            ..exerciseName = data['exerciseName']
            ..weight = (data['weight']).toDouble()
            ..reps = data['reps']
            ..date = DateTime.parse(data['date'])
            ..sessionId = data['sessionId'] as String?;
          await isar.exerciseSets.put(s);
        }

        // --- 6. PLANOS DE TREINO (AGORA MANTÉM O ID!) ---
        for (var doc in plansQuery.docs) {
          final data = doc.data();
          final plan = WorkoutPlan()
            ..id =
                int.tryParse(doc.id) ?? Isar.autoIncrement // <--- CORREÇÃO AQUI
            ..name = data['name']
            ..lastUpdated = DateTime.parse(data['lastUpdated']);
          await isar.workoutPlans.put(plan);

          if (data['days'] != null) {
            for (var dData in data['days']) {
              final day = WorkoutDay()..name = dData['name'];
              await isar.workoutDays.put(day);
              plan.days.add(day);

              if (dData['exercises'] != null) {
                for (var eData in dData['exercises']) {
                  final exercise = WorkoutExercise()
                    ..name = eData['name']
                    ..sets = eData['sets']
                    ..reps = eData['reps']
                    ..weight = (eData['weight']).toDouble()
                    ..notes = eData['notes'];
                  await isar.workoutExercises.put(exercise);
                  day.exercises.add(exercise);
                }
                await day.exercises.save();
              }
            }
            await plan.days.save();
          }
        }
      });

      debugPrint('Restauro perfeito da nuvem concluído com IDs originais!');
      return true;
    } catch (e) {
      debugPrint('Erro no restauro da nuvem: $e');
      return false;
    }
  }
}
