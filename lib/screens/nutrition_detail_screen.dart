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
    final sortedKeys =
        AppConstants.mealOrder.where((k) => mealGroups.containsKey(k)).toList();
    for (final k in mealGroups.keys) {
      if (!sortedKeys.contains(k)) sortedKeys.add(k);
    }

    final localeCode = Localizations.localeOf(context).toString();
    final dateStr = DateFormat('EEEE, d MMMM', localeCode).format(selectedDate);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 10, left: 8, right: 16),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(width: 12),
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
                      color: const Color(0xFF00E676).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateStr.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.nutritionSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
        physics: const BouncingScrollPhysics(),
        children: [
          _CalorieHero(
              data: data,
              activeColor: activeColor,
              isExceeded: isExceeded,
              l10n: l10n),
          const SizedBox(height: 24),
          _SectionTitle(
            icon: Icons.pie_chart_rounded,
            title: l10n.macroDistribution,
            color: const Color(0xFF29B6F6),
          ),
          const SizedBox(height: 14),
          _MacroCards(data: data, l10n: l10n),
          const SizedBox(height: 28),
          if (data.meals.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.restaurant_rounded,
              title: l10n.byMeal,
              color: const Color(0xFF00E676),
            ),
            const SizedBox(height: 14),
            ...sortedKeys.map((key) => _MealGroupCard(
                  mealKey: key,
                  meals: mealGroups[key]!,
                  totalDayKcal: data.eatenKcal,
                  l10n: l10n,
                )),
          ] else
            _EmptyMeals(l10n: l10n),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyMeals({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.no_meals_rounded,
              size: 56, color: colorScheme.onSurface.withValues(alpha: 0.16)),
          const SizedBox(height: 12),
          Text(
            l10n.noMealsRegistered,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.48),
              fontWeight: FontWeight.w600,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final gauge = CircularPercentIndicator(
          radius: isCompact ? 56 : 64,
          lineWidth: 9,
          percent: data.progress.clamp(0.0, 1.0),
          animation: true,
          animationDuration: 1400,
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.07),
          progressColor: activeColor,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${remaining.toInt()}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isCompact ? 20 : 22,
                  height: 1.0,
                  color: activeColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isExceeded
                    ? l10n.exceeded.toUpperCase()
                    : l10n.remaining.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );

        final stats = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExceeded ? Icons.warning_rounded : Icons.bolt_rounded,
                  size: 18,
                  color: activeColor,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${remaining.toInt()} ${l10n.unitKcal} ${isExceeded ? l10n.exceeded : l10n.remaining}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: activeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  _StatRow(
                      label: l10n.goal,
                      value: '${data.targetKcal.toInt()} ${l10n.unitKcal}',
                      valueColor:
                          colorScheme.onSurface.withValues(alpha: 0.62)),
                  const SizedBox(height: 10),
                  _StatRow(
                      label: l10n.consumed,
                      value: '${data.eatenKcal.toInt()} ${l10n.unitKcal}',
                      valueColor: activeColor),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: activeColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: isCompact
              ? Column(
                  children: [
                    gauge,
                    const SizedBox(height: 20),
                    stats,
                  ],
                )
              : Row(
                  children: [
                    gauge,
                    const SizedBox(width: 24),
                    Expanded(child: stats),
                  ],
                ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow(
      {required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
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
                fontSize: 10, fontWeight: FontWeight.bold, color: displayColor),
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
          border:
              Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
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
                          backgroundColor:
                              colorScheme.onSurface.withValues(alpha: 0.07),
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
                      _MacroChip('P ${totalProt.toInt()}${l10n.unitG}',
                          const Color(0xFF29B6F6)),
                      const SizedBox(width: 6),
                      _MacroChip('H ${totalCarbs.toInt()}${l10n.unitG}',
                          const Color(0xFFFFB74D)),
                      const SizedBox(width: 6),
                      _MacroChip('G ${totalFat.toInt()}${l10n.unitG}',
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
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(width: 10),
          Text('${meal.kcal.toInt()} kcal',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
