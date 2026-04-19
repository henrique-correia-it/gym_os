import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../data/database.dart';
import '../data/models/nutrition.dart';
import '../data/models/workout.dart';
import '../data/models/user.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db;

  MigrationService(this._db);

  Future<bool> migrateDataIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      // 1. Verifica se já foi feita a migração perfeita
      final docSnap = await userRef.get();
      if (docSnap.exists && docSnap.data()?['migrated'] == true) {
        return false; // Já migrado, entra na app
      }

      debugPrint('A iniciar extração manual e inteligente do Isar...');

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
        });
        operationCount++;
      }

      // --- 2. ALIMENTOS ---
      final foods = await isar.foodItems.where().findAll();
      for (var food in foods) {
        // A MAGIA QUE FALTAVA PARA AS MARMITAS: Carregar os ingredientes!
        await food.ingredients.load();

        List<Map<String, dynamic>> ingredientsList = food.ingredients
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
          'ingredients':
              ingredientsList, // <-- AGORA SIM, OS INGREDIENTES VÃO JUNTOS!
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

      // --- 4. CARGAS E RECORDES (ExerciseSets) ---
      final sets = await isar.exerciseSets.where().findAll();
      for (var s in sets) {
        batch.set(userRef.collection('exerciseSets').doc(s.id.toString()), {
          'exerciseName': s.exerciseName,
          'weight': s.weight,
          'reps': s.reps,
          'date': s.date.toIso8601String(),
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 5. REGISTOS DIÁRIOS (COM AS REFEIÇÕES EMBUTIDAS) ---
      final days = await isar.dayLogs.where().findAll();
      for (var day in days) {
        await day.meals
            .load(); // A MAGIA: Carrega as refeições associadas a este dia!

        List<Map<String, dynamic>> mealsList = day.meals
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
                })
            .toList();

        // Usa a data como ID do documento (ex: "2023-10-25") para facilitar a pesquisa depois
        String docId = day.date.toIso8601String().split('T')[0];

        batch.set(userRef.collection('dayLogs').doc(docId), {
          'date': day.date.toIso8601String(),
          'targetKcal': day.targetKcal,
          'consumedKcal': day.consumedKcal,
          'meals': mealsList, // Guarda as refeições DENTRO do dia!
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 6. PLANOS DE TREINO (COM DIAS E EXERCÍCIOS EMBUTIDOS) ---
      final plans = await isar.workoutPlans.where().findAll();
      for (var plan in plans) {
        await plan.days.load();

        List<Map<String, dynamic>> daysList = [];
        for (var d in plan.days) {
          await d.exercises.load(); // Carrega os exercícios daquele dia

          List<Map<String, dynamic>> exercisesList = d.exercises
              .map((e) => {
                    'name': e.name,
                    'sets': e.sets,
                    'reps': e.reps,
                    'weight': e.weight,
                    'notes': e.notes,
                  })
              .toList();

          daysList.add({
            'name': d.name,
            'exercises': exercisesList,
          });
        }

        batch.set(userRef.collection('workoutPlans').doc(plan.id.toString()), {
          'name': plan.name,
          'lastUpdated': plan.lastUpdated.toIso8601String(),
          'days': daysList, // Guarda os dias e exercícios DENTRO do plano!
        });
        operationCount++;
        await commitBatchIfNeeded();
      }

      // --- 7. FINALIZAR ---
      // Marca a conta como migrada com sucesso
      batch.set(
          userRef,
          {
            'migrated': true,
            'email': user.email,
            'migratedAt': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true));

      await batch.commit();

      debugPrint('Migração PERFEITA para a nuvem concluída com sucesso!');
      return true;
    } catch (e) {
      debugPrint('Erro fatal na migração: $e');
      return false;
    }
  }
}
