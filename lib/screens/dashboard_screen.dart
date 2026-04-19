import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_os/l10n/app_localizations.dart';

import 'package:isar/isar.dart';

import '../data/models/nutrition.dart';

import '../widgets/dashboard_meal_list.dart';

import 'package:intl/intl.dart';

import '../widgets/dashboard_calorie_card.dart';

import '../providers/dashboard_provider.dart';

import '../providers/app_providers.dart';

import '../services/cloud_sync_service.dart';

import 'tools/weight_history_screen.dart';
import 'nutrition_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final selectedDate = ref.watch(selectedDateProvider);


    final dateString =
        DateFormat('EEEE, d MMM').format(selectedDate).toUpperCase();

    // --- REGRAS DE DATAS ---

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final selectedMidnight =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final isToday = DateUtils.isSameDay(selectedDate, now);

    final isTomorrow =
        DateUtils.isSameDay(selectedDate, now.add(const Duration(days: 1)));

    final isYesterday = DateUtils.isSameDay(
        selectedDate, now.subtract(const Duration(days: 1)));

    // Verifica se é um dia anterior a hoje

    final isPast = selectedMidnight.isBefore(today);

    // Botão de apagar aparece HOJE, ONTEM e AMANHÃ

    final showDeleteButton = isToday || isYesterday || isTomorrow;

    // Botão de copiar aparece HOJE ou no PASSADO

    final showCopyButton = (isToday || isPast) && !isTomorrow;

    // Impedir de retroceder além do primeiro log

    final firstLogDateAsync = ref.watch(firstLogDateProvider);

    final firstLogDate = firstLogDateAsync.valueOrNull;

    bool canGoBack = true;

    if (firstLogDate != null) {
      final firstMidnight =
          DateTime(firstLogDate.year, firstLogDate.month, firstLogDate.day);

      if (!selectedMidnight.isAfter(firstMidnight)) {
        canGoBack = false; // Estamos no primeiro dia ou antes: não pode recuar
      }
    } else {
      // Se ainda não houver nenhum DayLog na base de dados, não permite recuar além de hoje

      if (!selectedMidnight.isAfter(today)) {
        canGoBack = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (canGoBack)
                  _buildDateButton(context, icon: Icons.chevron_left_rounded,
                      onTap: () {
                    final newDate =
                        selectedDate.subtract(const Duration(days: 1));
                    ref.read(selectedDateProvider.notifier).state = newDate;
                  })
                else
                  const SizedBox(width: 36),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    dateString,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isTomorrow)
                  _buildDateButton(context, icon: Icons.chevron_right_rounded,
                      onTap: () {
                    final newDate = selectedDate.add(const Duration(days: 1));
                    ref.read(selectedDateProvider.notifier).state = newDate;
                  })
                else
                  const SizedBox(width: 36),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                ref.read(navIndexProvider.notifier).state = 4;
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E676), width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.surface,
                  child: const Icon(Icons.person,
                      size: 20, color: Color(0xFF00E676)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("${l10n.error}: $err",
              style: const TextStyle(color: Colors.red)),
        )),
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NutritionDetailScreen(
                        data: data,
                        selectedDate: selectedDate,
                      ),
                    ),
                  ),
                  child: DashboardCalorieCard(data: data),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        l10n,
                        icon: Icons.monitor_weight_outlined,
                        color: Colors.blueAccent,
                        title: l10n.weight,
                        value: "${data.weight} kg",
                        subValue: l10n.history,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const WeightHistoryScreen())),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        l10n,
                        icon: Icons.accessibility_new_rounded,
                        color: Colors.purpleAccent,
                        title: l10n.imc,
                        value: data.imc.toStringAsFixed(1),
                        subValue:
                            _getTranslatedImcStatus(context, data.imcStatus),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- CABEÇALHO DA LISTA DE REFEIÇÕES ---

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(l10n.meals,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),

                        // BOTÃO DE COPIAR INTELIGENTE (Hoje ou Passado)

                        if (showCopyButton && data.meals.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_all_rounded, size: 20),
                            tooltip: l10n.copyMealsTo,
                            color: const Color(0xFF00E676),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676)
                                  .withValues(alpha: 0.15),
                              padding: const EdgeInsets.all(8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _handleSmartCopy(
                                context, ref, data.meals, isToday, today),
                          ),
                        ],

                        // BOTÃO DE APAGAR O DIA (Hoje, Ontem, Amanhã)

                        if (showDeleteButton && data.meals.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 20),
                            tooltip: l10n.clearDay,
                            color: colorScheme.error,
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.errorContainer
                                  .withValues(alpha: 0.3),
                              padding: const EdgeInsets.all(8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                _clearDailyMeals(context, ref, selectedDate),
                          ),
                        ]
                      ],
                    ),
                    if (data.isEditable)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                ref.read(navIndexProvider.notifier).state = 1,
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xFF00E676), size: 28),
                            tooltip: l10n.addFood,
                          ),
                          TextButton(
                              onPressed: () =>
                                  ref.read(navIndexProvider.notifier).state = 1,
                              child: Text(l10n.viewDiary)),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(l10n.readOnly,
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12)),
                      )
                  ],
                ),

                const SizedBox(height: 10),

                DashboardMealList(
                    meals: data.meals, isEditable: data.isEditable),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _clearDailyMeals(
      BuildContext context, WidgetRef ref, DateTime date) async {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.clearDayTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.clearDayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction,
                style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAll,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final dbService = ref.read(databaseProvider);

    final isar = dbService.isar;

    try {
      DayLog? log;

      await isar.writeTxn(() async {
        final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);

        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

        log = await isar.dayLogs
            .filter()
            .dateBetween(startOfDay, endOfDay)
            .findFirst();

        if (log != null) {
          await log!.meals.load();

          final mealsToDelete = log!.meals.toList();

          log!.meals.clear();

          await log!.meals.save();

          if (mealsToDelete.isNotEmpty) {
            await isar.mealEntrys
                .deleteAll(mealsToDelete.map((m) => m.id).toList());
          }

          await isar.dayLogs.put(log!);
        }
      });

      if (log != null) CloudSyncService(dbService).syncDayLog(log!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dayClearedSuccess),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint(l10n.errorClearingDay(e.toString()));
    }
  }

  Future<void> _handleSmartCopy(BuildContext context, WidgetRef ref,
      List<MealEntry> currentMeals, bool isToday, DateTime today) async {
    final tomorrow = today.add(const Duration(days: 1));

    if (isToday) {
      await _copyMealsToDate(context, ref, currentMeals, tomorrow);
    } else {
      final targetDate =
          await _showCopyDestinationDialog(context, today, tomorrow);

      if (targetDate != null && context.mounted) {
        await _copyMealsToDate(context, ref, currentMeals, targetDate);
      }
    }
  }

  Future<DateTime?> _showCopyDestinationDialog(
      BuildContext context, DateTime today, DateTime tomorrow) async {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        titlePadding: const EdgeInsets.only(top: 24),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.copy_all_rounded,
                  color: Color(0xFF00E676), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.copyMealsTo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.chooseDestinationDay,
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // --- CARTÃO: PARA HOJE ---

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(ctx, today),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.today_rounded, color: colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n.forToday,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: colorScheme.primary.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- CARTÃO: PARA AMANHÃ ---

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(ctx, tomorrow),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note_rounded,
                          color: Color(0xFF00E676)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          l10n.forTomorrow,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color:
                              const Color(0xFF00E676).withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(l10n.cancelAction,
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyMealsToDate(BuildContext context, WidgetRef ref,
      List<MealEntry> currentMeals, DateTime targetDate) async {
    final dbService = ref.read(databaseProvider);
    final isar = dbService.isar;
    final scaffold = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // --- CÁLCULO DINÂMICO DO NOME DO DIA ---
    final startOfTarget =
        DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
    final endOfTarget =
        DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));
    final targetMidnight =
        DateTime(targetDate.year, targetDate.month, targetDate.day);

    String targetName = "";
    if (targetMidnight == todayMidnight) {
      targetName = l10n.today;
    } else if (targetMidnight == tomorrowMidnight) {
      targetName = l10n.tomorrow;
    } else {
      targetName = DateFormat('dd/MM/yyyy').format(targetDate);
    }

    try {
      debugPrint("🔍 [CÓPIA] A iniciar processo de cópia para $targetName...");

      // 1. LEITURA FORA DA TRANSAÇÃO (Isto previne o erro "Nesting Transactions")
      debugPrint(
          "🔍 [CÓPIA] A procurar se já existe um DayLog para este dia...");
      var targetLog = await isar.dayLogs
          .filter()
          .dateBetween(startOfTarget, endOfTarget)
          .findFirst();

      bool shouldProceed = true;

      if (targetLog != null) {
        debugPrint(
            "🔍 [CÓPIA] DayLog encontrado. A carregar as refeições existentes (.load())...");
        // A leitura das refeições também tem de ser FORA do writeTxn
        await targetLog.meals.load();

        if (targetLog.meals.isNotEmpty) {
          if (!context.mounted) return;
          debugPrint(
              "🔍 [CÓPIA] O dia de destino já contém dados. A pedir confirmação...");

          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.recordsInTarget(targetName),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Text(l10n.targetHasRecordsMessage(targetName)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel,
                      style: const TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.add,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          if (confirm != true) {
            debugPrint("🔍 [CÓPIA] Cópia cancelada pelo utilizador.");
            shouldProceed = false;
          }
        }
      } else {
        debugPrint(
            "🔍 [CÓPIA] Nenhum DayLog encontrado. A instanciar um novo (apenas em memória)...");
        // Cria apenas na memória, não gravamos ainda.
        targetLog = DayLog()..date = targetDate;
      }

      if (!shouldProceed) return;

      // 2. PREPARAR OS DADOS (Tudo na memória)
      debugPrint(
          "🔍 [CÓPIA] A preparar ${currentMeals.length} refeições para copiar...");
      final List<MealEntry> newMeals = [];

      for (var meal in currentMeals) {
        final newMeal = MealEntry()
          ..foodName = meal.foodName
          ..amount = meal.amount
          ..unit = meal.unit
          ..baseKcal = meal.baseKcal
          ..baseProtein = meal.baseProtein
          ..baseCarbs = meal.baseCarbs
          ..baseFat = meal.baseFat
          ..kcal = meal.kcal
          ..protein = meal.protein
          ..carbs = meal.carbs
          ..fat = meal.fat
          ..type = meal.type;

        newMeals.add(newMeal);
      }

      // 3. TRANSAÇÃO (Apenas operações de gravação)
      debugPrint("🔍 [CÓPIA] A abrir a writeTxn para gravar na BD...");
      await isar.writeTxn(() async {
        // Colocamos o targetLog na BD para garantir que ganha um ID válido (caso seja novo)
        await isar.dayLogs.put(targetLog!);

        // Guardar primeiro todos os itens da refeição para terem os IDs gerados
        await isar.mealEntrys.putAll(newMeals);

        // Adicionar os itens gerados à ligação (links) e guardar a ligação
        targetLog.meals.addAll(newMeals);
        await targetLog.meals.save();

        // Recalcular as calorias consumidas do dia (somatório simples)
        double sumKcal = 0;
        for (var m in targetLog.meals) {
          sumKcal += m.kcal;
        }
        targetLog.consumedKcal = sumKcal;

        // Atualizar o DayLog com o total de calorias
        await isar.dayLogs.put(targetLog);
      });
      debugPrint("🔍 [CÓPIA] writeTxn concluída com sucesso!");

      // 4. SINCRONIZAÇÃO
      debugPrint("🔍 [CÓPIA] A preparar para enviar para a Cloud...");
      final syncLog = await isar.dayLogs
          .filter()
          .dateBetween(startOfTarget, endOfTarget)
          .findFirst();

      if (syncLog != null) {
        CloudSyncService(dbService).syncDayLog(syncLog);
        debugPrint("🔍 [CÓPIA] Sincronização chamada.");
      }

      if (context.mounted) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(l10n.mealsCopiedTargetSuccess(targetName)),
            backgroundColor: const Color(0xFF00E676),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } catch (e, stacktrace) {
      debugPrint("❌ [ERRO NA CÓPIA] Falha na operação: $e");
      debugPrint("❌ [STACKTRACE] $stacktrace");
      if (context.mounted) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(l10n.errorCopying(e.toString())),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDateButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AppLocalizations l10n,
      {required IconData icon,
      required Color color,
      required String title,
      required String value,
      required String subValue,
      required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        overlayColor: WidgetStateProperty.all(color.withValues(alpha: 0.1)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),

                blurRadius: 15, // Reduzido

                offset: const Offset(0, 6), // Menos deslocado
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone com fundo circular suave

              Container(
                padding: const EdgeInsets.all(10), // Reduzido

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),

                child: Icon(icon, color: color, size: 22), // Reduzido de 26
              ),

              const SizedBox(height: 12), // Reduzido de 16

              // Título (ex: PESO, IMC)

              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10, // Reduzido de 11

                  fontWeight: FontWeight.w700,

                  letterSpacing: 1.2, // Reduzido

                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4), // Reduzido de 6

              // Valor Principal (ex: 70kg, 24.5)

              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,

                  fontSize: 20, // Reduzido de 24

                  letterSpacing: -0.5,

                  color: colorScheme.onSurface,

                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Subvalor / Estado (ex: Histórico, Normal, Obesidade)

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3), // Pílula menor

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),

                  borderRadius: BorderRadius.circular(8), // Reduzido de 12
                ),

                child: Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 10, // Reduzido de 11

                    color: color,

                    fontWeight: FontWeight.w600,

                    letterSpacing: 0.2, // Reduzido
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTranslatedImcStatus(BuildContext context, IMCStatus status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
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
