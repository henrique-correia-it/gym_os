import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/data/models/nutrition.dart';
import 'package:isar/isar.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADICIONADO
import '../data/database.dart';
import '../data/models/user.dart';
import 'package:intl/intl.dart';

// Provider da Base de Dados
final databaseProvider =
    Provider<DatabaseService>((ref) => throw UnimplementedError());

// NOVO: Provider que escuta o estado de autenticação do Firebase em tempo real
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provider do Tema
final themeStringProvider = StateProvider<String>((ref) => "system");

// Provider do Index de Navegação
final navIndexProvider = StateProvider<int>((ref) => 0);

// Provider da Data Selecionada no Dashboard (Inicia com Hoje)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // Normaliza para meia-noite para evitar problemas de horas
  return DateTime(now.year, now.month, now.day);
});

// Provider que observa o utilizador em tempo real
final userSettingsProvider = StreamProvider<UserSettings?>((ref) {
  final db = ref.watch(databaseProvider);

  return db.isar.userSettings
      .where()
      .watch(fireImmediately: true)
      .map((list) => list.isNotEmpty ? list.first : null);
});

// Provider da Língua (Reativo e Sincronizado)
final localeProvider = Provider<Locale>((ref) {
  // 1. Observa o StreamProvider do utilizador.
  // O .when garante que lidamos com os estados de loading/erro/data
  final userSettingsAsync = ref.watch(userSettingsProvider);

  return userSettingsAsync.when(
    data: (userSettings) {
      // Se não houver settings (primeiro boot), usa PT
      if (userSettings == null) return const Locale('pt', 'PT');

      final lang = userSettings.language;

      // Define o Locale
      Locale newLocale;
      if (lang == 'en') {
        newLocale = const Locale('en', 'US');
      } else if (lang == 'es') {
        newLocale = const Locale('es', 'ES');
      } else {
        newLocale = const Locale('pt', 'PT');
      }

      // CRÍTICO: Atualiza o Intl globalmente para formatação de datas
      Intl.defaultLocale = newLocale.toString();
      return newLocale;
    },
    // Fallback enquanto carrega
    loading: () => const Locale('pt', 'PT'),
    error: (_, __) => const Locale('pt', 'PT'),
  );
});

// Provider da ordem das refeições (lista custom ou defaults)
final mealOrderProvider = Provider<List<String>>((ref) {
  final custom =
      ref.watch(userSettingsProvider).valueOrNull?.customMealOrder ?? [];
  if (custom.isNotEmpty) return List<String>.unmodifiable(custom);
  return const [
    'Peq. Almoço',
    'Almoço',
    'Lanche',
    'Jantar',
    'Pré-Treino',
    'Pós-Treino',
    'Ceia',
  ];
});

// Provider que obtém a data do primeiro diário registado
final firstLogDateProvider = StreamProvider.autoDispose<DateTime?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.isar.dayLogs
      .where()
      .sortByDate()
      .watch(fireImmediately: true)
      .map((logs) => logs.isNotEmpty ? logs.first.date : null);
});
