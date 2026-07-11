// Ficheiro: lib/widgets/dashboard_meal_list.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../data/models/nutrition.dart';
import '../providers/app_providers.dart';
import '../services/cloud_sync_service.dart';
import '../utils/app_toast.dart';
import '../utils/constants.dart';

class DashboardMealList extends ConsumerStatefulWidget {
  final List<MealEntry> meals;
  final bool isEditable;

  const DashboardMealList({
    super.key,
    required this.meals,
    required this.isEditable,
  });

  @override
  ConsumerState<DashboardMealList> createState() => _DashboardMealListState();
}

class _DashboardMealListState extends ConsumerState<DashboardMealList> {
  // ── Auto-scroll during drag ──────────────────────────────────────────────
  Timer? _scrollTimer;
  double _scrollSpeed = 0;
  static const _edgeThreshold = 130.0;
  static const _maxScrollSpeed = 500.0;

  // ── Drag state ───────────────────────────────────────────────────────────
  MealEntry? _draggingMeal;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _onDragUpdate(Offset globalPos, BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final y = globalPos.dy;
    double speed = 0;
    if (y < _edgeThreshold) {
      speed = -_maxScrollSpeed * (1 - y / _edgeThreshold);
    } else if (y > screenHeight - _edgeThreshold) {
      speed = _maxScrollSpeed * (1 - (screenHeight - y) / _edgeThreshold);
    }
    _scrollSpeed = speed;
    if (speed != 0 && _scrollTimer == null) {
      ScrollPosition? pos;
      try { pos = Scrollable.of(context).position; } catch (_) { return; }
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted) { _scrollTimer?.cancel(); _scrollTimer = null; return; }
        final next = (pos!.pixels + _scrollSpeed / 60)
            .clamp(pos.minScrollExtent, pos.maxScrollExtent);
        pos.jumpTo(next);
      });
    } else if (speed == 0) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
    }
  }

  void _stopScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _scrollSpeed = 0;
  }

  // ── Sort-order helpers ───────────────────────────────────────────────────
  double _effectiveSortOrder(MealEntry m) => m.sortOrder ?? m.id.toDouble();

  /// Returns the sortOrder a new item should have when inserted BEFORE [index]
  /// in [group] (which must already be sorted ascending by sortOrder).
  double _sortOrderAt(List<MealEntry> group, int index) {
    if (group.isEmpty) return 1000;
    if (index <= 0) return _effectiveSortOrder(group.first) - 1000;
    if (index >= group.length) return _effectiveSortOrder(group.last) + 1000;
    return (_effectiveSortOrder(group[index - 1]) +
            _effectiveSortOrder(group[index])) /
        2;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meals.isEmpty) {
      return _buildEmptyStatePlaceholder(context);
    }

    final Map<String, List<MealEntry>> grouped = {};
    for (var meal in widget.meals) {
      String type = meal.type.trim();
      if (type.isEmpty) type = AppLocalizations.of(context)!.others;
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(meal);
    }

    List<String> order = ref.watch(mealOrderProvider);
    final List<String> displayKeys = [];

    for (var o in order) {
      if (grouped.containsKey(o)) displayKeys.add(o);
    }
    for (var key in grouped.keys) {
      if (!displayKeys.contains(key)) displayKeys.add(key);
    }

    return Column(
      children: displayKeys.map((type) {
        final groupMeals = grouped[type]!;
        final totalGroupKcal = groupMeals.fold(0.0, (sum, m) => sum + m.kcal);
        final translatedTitle = TranslationHelper.getMealName(context, type);

        // --- LÓGICA DE DRAG & DROP ---
        if (widget.isEditable) {
          final isDragging = _draggingMeal != null;
          final draggingId = _draggingMeal?.id;

          // Build list interleaved with drop zones (placeholder is inside each zone)
          final itemWidgets = <Widget>[];
          for (int i = 0; i < groupMeals.length; i++) {
            final capturedType = type;
            if (i == 0) {
              final order = _sortOrderAt(groupMeals, 0);
              itemWidgets.add(_InsertionZone(
                onAccept: (m) => _moveMealToPosition(m, capturedType, order),
                isActiveDrag: isDragging,
                draggingMealId: draggingId,
                prevMealId: null,
                nextMealId: groupMeals[0].id,
              ));
            }
            itemWidgets.add(_buildMealItem(context, groupMeals[i]));
            final afterZoneIndex = i + 1;
            final order = _sortOrderAt(groupMeals, afterZoneIndex);
            itemWidgets.add(_InsertionZone(
              onAccept: (m) => _moveMealToPosition(m, capturedType, order),
              isActiveDrag: isDragging,
              draggingMealId: draggingId,
              prevMealId: groupMeals[i].id,
              nextMealId: afterZoneIndex < groupMeals.length ? groupMeals[afterZoneIndex].id : null,
            ));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  context, type, translatedTitle, totalGroupKcal, groupMeals),
              ...itemWidgets,
              Divider(
                  height: 30,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ],
          );
        } else {
          // Versão não editável
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  context, type, translatedTitle, totalGroupKcal, groupMeals),
              ...groupMeals.map((meal) => _buildMealItem(context, meal)),
              Divider(
                  height: 30,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ],
          );
        }
      }).toList(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String mealTypeKey,
      String title, double totalKcal, List<MealEntry> groupMeals) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF00E676))),
          Row(
            children: [
              Text("${totalKcal.toStringAsFixed(0)} kcal",
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showCopyMealBottomSheet(context, mealTypeKey, title, groupMeals),
                child: Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCopyMealBottomSheet(BuildContext context, String mealTypeKey,
      String mealTitle, List<MealEntry> groupMeals) {
    final l10n = AppLocalizations.of(context)!;
    final mealOrder = ref.read(mealOrderProvider);
    final selectedDate = ref.read(selectedDateProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final currentDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // Destination options — exclude the day currently being viewed
    final destinations = <_CopyDestination>[
      if (currentDay != today) _CopyDestination(label: l10n.forToday, date: today),
      _CopyDestination(label: l10n.forTomorrow, date: tomorrow),
    ];

    if (destinations.isEmpty) return; // already tomorrow, nowhere to go

    DateTime selectedDest = destinations.first.date;
    // Pre-select source meal type if it exists in the user's meal order
    String? selectedTargetType =
        mealOrder.contains(mealTypeKey) ? mealTypeKey : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final isEnabled = selectedTargetType != null;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              top: 12,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // — Drag handle —
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // — Header —
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E676), Color(0xFF00C853)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.copy_all_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.copyMeal,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 19)),
                          Text(mealTitle,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // — Destination date —
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 13,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(l10n.chooseDestinationDay,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(ctx).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.3)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: destinations.asMap().entries.map((entry) {
                    final i = entry.key;
                    final dest = entry.value;
                    final selected = selectedDest == dest.date;
                    final isToday = dest.date == today;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: i < destinations.length - 1 ? 10 : 0),
                        child: GestureDetector(
                          onTap: () =>
                              setSheet(() => selectedDest = dest.date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF00E676)
                                      .withValues(alpha: 0.12)
                                  : Theme.of(ctx)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF00E676)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  isToday
                                      ? Icons.today_rounded
                                      : Icons.event_rounded,
                                  size: 22,
                                  color: selected
                                      ? const Color(0xFF00E676)
                                      : Theme.of(ctx)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                                const SizedBox(height: 6),
                                Text(dest.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: selected
                                          ? const Color(0xFF00E676)
                                          : Theme.of(ctx)
                                              .colorScheme
                                              .onSurface,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // — Target meal type —
                Row(
                  children: [
                    Icon(Icons.restaurant_rounded,
                        size: 13,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(l10n.chooseMealType,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(ctx).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.3)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: mealOrder.map((type) {
                    final selected = selectedTargetType == type;
                    final label = TranslationHelper.getMealName(ctx, type);
                    return GestureDetector(
                      onTap: () =>
                          setSheet(() => selectedTargetType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF00E676)
                                  .withValues(alpha: 0.12)
                              : Theme.of(ctx)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF00E676)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: selected
                                  ? const Color(0xFF00E676)
                                  : Theme.of(ctx).colorScheme.onSurface,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // — Confirm button —
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isEnabled
                          ? const LinearGradient(
                              colors: [Color(0xFF00E676), Color(0xFF00C853)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isEnabled
                          ? null
                          : Theme.of(ctx)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isEnabled
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: isEnabled
                            ? Colors.white
                            : Theme.of(ctx)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.35),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: isEnabled
                          ? () {
                              Navigator.pop(ctx);
                              _copyMealGroupToDate(
                                groupMeals,
                                selectedDest,
                                selectedTargetType!,
                              );
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.copy_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.copyMeal,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _copyMealGroupToDate(
    List<MealEntry> groupMeals,
    DateTime targetDate,
    String targetMealType,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    final isar = db.isar;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetMidnight =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    final targetName = targetMidnight == today
        ? l10n.today
        : targetMidnight == tomorrow
            ? l10n.tomorrow
            : DateFormat('dd/MM/yyyy').format(targetDate);

    final startOfTarget = DateTime(
        targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
    final endOfTarget = DateTime(
        targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    try {
      var targetLog = await isar.dayLogs
          .filter()
          .dateBetween(startOfTarget, endOfTarget)
          .findFirst();

      if (targetLog != null) {
        await targetLog.meals.load();
      } else {
        targetLog = DayLog()..date = targetDate;
      }

      // Build the new meal entries with the chosen target type
      final newMeals = groupMeals
          .map((m) => MealEntry()
            ..foodName = m.foodName
            ..amount = m.amount
            ..unit = m.unit
            ..baseKcal = m.baseKcal
            ..baseProtein = m.baseProtein
            ..baseCarbs = m.baseCarbs
            ..baseFat = m.baseFat
            ..kcal = m.kcal
            ..protein = m.protein
            ..carbs = m.carbs
            ..fat = m.fat
            ..type = targetMealType)
          .toList();

      await isar.writeTxn(() async {
        await isar.dayLogs.put(targetLog!);
        await isar.mealEntrys.putAll(newMeals);
        targetLog.meals.addAll(newMeals);
        await targetLog.meals.save();

        double sumKcal = 0;
        for (var m in targetLog.meals) {
          sumKcal += m.kcal;
        }
        targetLog.consumedKcal = sumKcal;
        await isar.dayLogs.put(targetLog);
      });

      final syncLog = await isar.dayLogs
          .filter()
          .dateBetween(startOfTarget, endOfTarget)
          .findFirst();
      if (syncLog != null) CloudSyncService(db).syncDayLog(syncLog);

      if (mounted) {
        AppToast.show(context, l10n.mealsCopiedTargetSuccess(targetName));
      }
    } catch (e) {
      if (mounted) AppToast.show(context, l10n.error, isError: true);
    }
  }

  Future<void> _moveMealToPosition(
      MealEntry meal, String newType, double sortOrder) async {
    final db = ref.read(databaseProvider);
    final l10n = AppLocalizations.of(context)!;
    try {
      await db.isar.writeTxn(() async {
        meal.type = newType;
        meal.sortOrder = sortOrder;
        await db.isar.mealEntrys.put(meal);
      });
      final selectedDate = ref.read(selectedDateProvider);
      final log =
          await db.isar.dayLogs.filter().dateEqualTo(selectedDate).findFirst();
      if (log != null) CloudSyncService(db).syncDayLog(log);
      if (mounted) AppToast.show(context, l10n.updated);
    } catch (e) {
      if (mounted) AppToast.show(context, l10n.error);
    }
  }

  Widget _buildEmptyStatePlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.no_meals_outlined,
              size: 40, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(l10n.noMealsRegistered,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMealItem(BuildContext context, MealEntry meal) {
    if (!widget.isEditable) {
      return _buildMealVisual(context, meal);
    }

    final mealContent = GestureDetector(
      onTap: () => _showEditModal(meal),
      child: _buildMealVisual(context, meal),
    );

    return LongPressDraggable<MealEntry>(
      data: meal,
      delay: const Duration(milliseconds: 300),
      onDragStarted: () => setState(() => _draggingMeal = meal),
      onDragUpdate: (details) => _onDragUpdate(details.globalPosition, context),
      onDragEnd: (_) { _stopScroll(); setState(() { _draggingMeal = null; }); },
      onDraggableCanceled: (_, __) { _stopScroll(); setState(() { _draggingMeal = null; }); },
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Opacity(
            opacity: 0.9,
            child: _buildMealVisual(context, meal, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: Dismissible(
        key: Key(meal.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          final l10n = AppLocalizations.of(context)!;
          // --- MODAL PADRONIZADO (Delete Item) ---
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(l10n.deleteMealTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                content: Text(l10n.deleteMealMessage(meal.foodName)),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.delete,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (_) {
          _deleteMeal(meal);
        },
        child: mealContent,
      ),
    );
  }

  Widget _buildMealVisual(BuildContext context, MealEntry meal,
      {bool isDragging = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDragging
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20), // Arredondamento consistente
        border: Border.all(
            color: isDragging
                ? const Color(0xFF00E676)
                : Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        boxShadow: isDragging
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant,
                color: Colors.orangeAccent, size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.foodName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text("${meal.amount.toStringAsFixed(1)} ${meal.unit}",
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            "${meal.kcal.toStringAsFixed(0)} kcal",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          if (widget.isEditable && !isDragging) ...[
            const SizedBox(width: 8),
            Icon(Icons.drag_indicator,
                color: Colors.grey.withValues(alpha: 0.3), size: 18)
          ]
        ],
      ),
    );
  }

  Future<void> _deleteMeal(MealEntry meal) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final db = ref.read(databaseProvider);
      await db.isar.writeTxn(() async {
        await db.isar.mealEntrys.delete(meal.id);
      });
      final selectedDate = ref.read(selectedDateProvider);
      final log =
          await db.isar.dayLogs.filter().dateEqualTo(selectedDate).findFirst();
      if (log != null) CloudSyncService(db).syncDayLog(log);
      if (mounted) {
        AppToast.show(context, l10n.mealRemoved);
      }
    } catch (e) {
      if (mounted) AppToast.show(context, l10n.errorRemoving);
    }
  }

  void _showEditModal(MealEntry meal) {
    double currentAmount = meal.amount;
    final isUnit = meal.unit == 'un';
    final step = isUnit ? 0.5 : 1.0;
    final controller =
        TextEditingController(text: currentAmount.toStringAsFixed(isUnit ? 1 : 0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return StatefulBuilder(builder: (ctx, setModal) {
          final ratio = isUnit ? currentAmount : (currentAmount / 100.0);
          final kcal = meal.baseKcal * ratio;
          final prot = meal.baseProtein * ratio;
          final carbs = meal.baseCarbs * ratio;
          final fat = meal.baseFat * ratio;

          void adjustAmount(double delta) {
            final newVal = (currentAmount + delta).clamp(0.0, 9999.0);
            setModal(() => currentAmount = newVal);
            controller.text = newVal.toStringAsFixed(isUnit ? 1 : 0);
          }

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              top: 12,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // — Drag handle —
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // — Header do alimento —
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.restaurant_rounded,
                          color: Colors.orangeAccent, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.foodName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 17),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isUnit ? l10n.unitUn : l10n.unit100g,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // — Quantidade + kcal —
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Botão −
                      _buildStepButton(ctx, Icons.remove_rounded, () {
                        if (currentAmount > step) adjustAmount(-step);
                      }),
                      // Input + unidade
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              IntrinsicWidth(
                                child: TextField(
                                  controller: controller,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  autofocus: false,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    final v = double.tryParse(
                                            val.replaceAll(',', '.')) ??
                                        0;
                                    setModal(() => currentAmount = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isUnit ? 'un' : 'g',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão +
                      _buildStepButton(ctx, Icons.add_rounded, () {
                        adjustAmount(step);
                      }),
                      // Separador
                      Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1)),
                      // Kcal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            kcal.toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E676)),
                          ),
                          Text(l10n.unitKcal,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // — Macros em tempo real —
                Row(
                  children: [
                    _buildMacroLiveChip(ctx, l10n.protein, prot, const Color(0xFF29B6F6), l10n),
                    const SizedBox(width: 10),
                    _buildMacroLiveChip(ctx, l10n.carbs, carbs, const Color(0xFFFFB74D), l10n),
                    const SizedBox(width: 10),
                    _buildMacroLiveChip(ctx, l10n.fat, fat, const Color(0xFFE57373), l10n),
                  ],
                ),
                const SizedBox(height: 24),

                // — Botão guardar —
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF00E676).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        final finalRatio =
                            isUnit ? currentAmount : (currentAmount / 100.0);
                        await db.isar.writeTxn(() async {
                          meal.amount = currentAmount;
                          meal.kcal = meal.baseKcal * finalRatio;
                          meal.protein = meal.baseProtein * finalRatio;
                          meal.carbs = meal.baseCarbs * finalRatio;
                          meal.fat = meal.baseFat * finalRatio;
                          await db.isar.mealEntrys.put(meal);
                        });
                        final selectedDate = ref.read(selectedDateProvider);
                        final log = await db.isar.dayLogs
                            .filter()
                            .dateEqualTo(selectedDate)
                            .findFirst();
                        if (log != null) CloudSyncService(db).syncDayLog(log);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          AppToast.show(ctx, l10n.updated);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.save,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildStepButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildMacroLiveChip(BuildContext context, String shortLabel,
      double value, Color color, AppLocalizations l10n) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
                const SizedBox(width: 2),
                Text(l10n.unitG,
                    style: TextStyle(
                        fontSize: 10, color: color.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 4),
            Text(shortLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// Simple value class used inside the bottom sheet
class _CopyDestination {
  final String label;
  final DateTime date;
  const _CopyDestination({required this.label, required this.date});
}

// ── Insertion zone — DragTarget that shows placeholder when hovered ───────────
class _InsertionZone extends StatelessWidget {
  final void Function(MealEntry) onAccept;
  final bool isActiveDrag;
  final Id? draggingMealId;
  final Id? prevMealId;
  final Id? nextMealId;

  const _InsertionZone({
    required this.onAccept,
    required this.isActiveDrag,
    required this.draggingMealId,
    required this.prevMealId,
    required this.nextMealId,
  });

  bool get _isNoOp =>
      draggingMealId != null &&
      (prevMealId == draggingMealId || nextMealId == draggingMealId);

  @override
  Widget build(BuildContext context) {
    if (!isActiveDrag || _isNoOp) return const SizedBox.shrink();

    return DragTarget<MealEntry>(
      onWillAccept: (meal) => meal != null,
      onAccept: onAccept,
      builder: (context, candidateData, _) {
        final hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: hovering ? 68 : 10,
          margin: hovering ? const EdgeInsets.only(bottom: 10) : EdgeInsets.zero,
          decoration: hovering
              ? BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                )
              : null,
          child: hovering
              ? Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: const Color(0xFF00E676).withValues(alpha: 0.45),
                    size: 22,
                  ),
                )
              : null,
        );
      },
    );
  }
}
