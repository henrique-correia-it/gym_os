import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../data/models/nutrition.dart';
import '../l10n/app_localizations.dart';
import '../providers/dashboard_provider.dart';
import '../utils/constants.dart';

class NutritionDetailScreen extends StatelessWidget {
  final DashboardData data;
  final DateTime selectedDate;

  const NutritionDetailScreen({
    super.key,
    required this.data,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    const primaryColor = Color(0xFF00C853);
    const alertColor = Color(0xFFFF5252);
    final isExceeded = data.eatenKcal > data.targetKcal;
    final activeColor = isExceeded ? alertColor : primaryColor;

    // Agrupa as refeições por tipo
    final Map<String, List<MealEntry>> mealGroups = {};
    for (final meal in data.meals) {
      mealGroups.putIfAbsent(meal.type, () => []).add(meal);
    }
    final sortedKeys = AppConstants.mealOrder
        .where((k) => mealGroups.containsKey(k))
        .toList();
    for (final k in mealGroups.keys) {
      if (!sortedKeys.contains(k)) sortedKeys.add(k);
    }

    final localeCode = Localizations.localeOf(context).toString();
    final dateStr =
        DateFormat('EEEE, d MMMM', localeCode).format(selectedDate);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 64,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: colorScheme.onSurface),
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bar_chart_rounded,
                      size: 18, color: primaryColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.nutritionSummary,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(dateStr,
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.normal)),
                  ],
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalorieHero(
                      data: data,
                      activeColor: activeColor,
                      isExceeded: isExceeded,
                      l10n: l10n),
                  const SizedBox(height: 20),
                  _MacroCards(data: data, l10n: l10n),
                  const SizedBox(height: 30),
                  if (data.meals.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restaurant_rounded,
                              size: 15, color: Color(0xFF00E676)),
                        ),
                        const SizedBox(width: 10),
                        Text(l10n.byMeal,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...sortedKeys.map((key) => _MealGroupCard(
                          mealKey: key,
                          meals: mealGroups[key]!,
                          totalDayKcal: data.eatenKcal,
                          l10n: l10n,
                        )),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.no_meals_rounded,
                                size: 56,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.15)),
                            const SizedBox(height: 12),
                            Text(l10n.noMealsRegistered,
                                style: TextStyle(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.4))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero do círculo de calorias ───────────────────────────────────────────

class _CalorieHero extends StatelessWidget {
  final DashboardData data;
  final Color activeColor;
  final bool isExceeded;
  final AppLocalizations l10n;

  const _CalorieHero({
    required this.data,
    required this.activeColor,
    required this.isExceeded,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final remaining = (data.targetKcal - data.eatenKcal).abs();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: activeColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 64,
            lineWidth: 8,
            percent: data.progress.clamp(0.0, 1.0),
            animation: true,
            animationDuration: 1400,
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor:
                colorScheme.onSurface.withValues(alpha: 0.07),
            progressColor: activeColor,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${remaining.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    height: 1.0,
                    letterSpacing: -1.0,
                    color: activeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isExceeded
                      ? l10n.exceeded.toUpperCase()
                      : l10n.remaining.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                    label: l10n.goal,
                    value: '${data.targetKcal.toInt()} ${l10n.unitKcal}',
                    valueColor:
                        colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(height: 10),
                _StatRow(
                    label: l10n.consumed,
                    value: '${data.eatenKcal.toInt()} ${l10n.unitKcal}',
                    valueColor: activeColor),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                      height: 1,
                      color:
                          colorScheme.onSurface.withValues(alpha: 0.1)),
                ),
                Row(
                  children: [
                    Icon(
                      isExceeded
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      size: 15,
                      color: activeColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${remaining.toInt()} ${l10n.unitKcal} ${isExceeded ? l10n.exceeded : l10n.remaining}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: activeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow(
      {required this.label,
      required this.value,
      required this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: colorScheme.onSurfaceVariant)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }
}

// ─── Cards de macros ───────────────────────────────────────────────────────

class _MacroCards extends StatelessWidget {
  final DashboardData data;
  final AppLocalizations l10n;

  const _MacroCards({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _MacroCard(
                label: l10n.protein,
                value: data.eatenProtein,
                target: data.targetProtein,
                color: const Color(0xFF29B6F6),
                l10n: l10n)),
        const SizedBox(width: 10),
        Expanded(
            child: _MacroCard(
                label: l10n.carbs,
                value: data.eatenCarbs,
                target: data.targetCarbs,
                color: const Color(0xFFFFB74D),
                l10n: l10n)),
        const SizedBox(width: 10),
        Expanded(
            child: _MacroCard(
                label: l10n.fat,
                value: data.eatenFat,
                target: data.targetFat,
                color: const Color(0xFFE57373),
                l10n: l10n)),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final AppLocalizations l10n;

  const _MacroCard(
      {required this.label,
      required this.value,
      required this.target,
      required this.color,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final isOver = value > target && target > 0;
    final displayColor = isOver ? const Color(0xFFFF5252) : color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text(
            '${value.toInt()}${l10n.unitG}',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: displayColor,
                height: 1.0),
          ),
          Text(
            '/ ${target.toInt()}${l10n.unitG}',
            style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 4,
            percent: percent,
            padding: EdgeInsets.zero,
            barRadius: const Radius.circular(4),
            progressColor: displayColor,
            backgroundColor: color.withValues(alpha: 0.15),
            animation: true,
            animationDuration: 1200,
          ),
          const SizedBox(height: 6),
          Text(
            '${(percent * 100).toInt()}%',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: displayColor),
          ),
        ],
      ),
    );
  }
}

// ─── Card de grupo de refeição ─────────────────────────────────────────────

class _MealGroupCard extends StatelessWidget {
  final String mealKey;
  final List<MealEntry> meals;
  final double totalDayKcal;
  final AppLocalizations l10n;

  const _MealGroupCard({
    required this.mealKey,
    required this.meals,
    required this.totalDayKcal,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mealName = TranslationHelper.getMealName(context, mealKey);
    final totalKcal = meals.fold(0.0, (s, m) => s + m.kcal);
    final totalProt = meals.fold(0.0, (s, m) => s + m.protein);
    final totalCarbs = meals.fold(0.0, (s, m) => s + m.carbs);
    final totalFat = meals.fold(0.0, (s, m) => s + m.fat);
    final dayPercent =
        totalDayKcal > 0 ? (totalKcal / totalDayKcal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(mealName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '${totalKcal.toInt()} ${l10n.unitKcal}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF00C853)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearPercentIndicator(
                          lineHeight: 5,
                          percent: dayPercent,
                          padding: EdgeInsets.zero,
                          barRadius: const Radius.circular(4),
                          progressColor: const Color(0xFF00E676),
                          backgroundColor: colorScheme.onSurface
                              .withValues(alpha: 0.07),
                          animation: true,
                          animationDuration: 1000,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(dayPercent * 100).toInt()}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MacroChip(
                          'P ${totalProt.toInt()}${l10n.unitG}',
                          const Color(0xFF29B6F6)),
                      const SizedBox(width: 6),
                      _MacroChip(
                          'H ${totalCarbs.toInt()}${l10n.unitG}',
                          const Color(0xFFFFB74D)),
                      const SizedBox(width: 6),
                      _MacroChip(
                          'G ${totalFat.toInt()}${l10n.unitG}',
                          const Color(0xFFE57373)),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
                height: 1,
                color: colorScheme.onSurface.withValues(alpha: 0.07)),
            ...meals.map((m) => _FoodItem(meal: m, l10n: l10n)),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String text;
  final Color color;

  const _MacroChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _FoodItem extends StatelessWidget {
  final MealEntry meal;
  final AppLocalizations l10n;

  const _FoodItem({required this.meal, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final amountStr = meal.unit == 'un'
        ? '${meal.amount.toStringAsFixed(0)} un'
        : '${meal.amount.toStringAsFixed(0)}${l10n.unitG}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF00E676), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              meal.foodName,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(amountStr,
              style: TextStyle(
                  fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(width: 10),
          Text('${meal.kcal.toInt()} kcal',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
