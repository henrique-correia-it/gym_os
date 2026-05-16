import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../../data/models/workout.dart';
import '../../providers/app_providers.dart';

class LoadTrackerScreen extends ConsumerStatefulWidget {
  final String? initialExercise;

  const LoadTrackerScreen({super.key, this.initialExercise});

  @override
  ConsumerState<LoadTrackerScreen> createState() => _LoadTrackerScreenState();
}

class _LoadTrackerScreenState extends ConsumerState<LoadTrackerScreen> {
  String? _selectedExercise;
  List<String> _availableExercises = [];
  List<ExerciseSet> _history = [];
  Map<String, List<ExerciseSet>> _historyByExercise = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    final db = ref.read(databaseProvider);
    final sets = await db.isar.exerciseSets
        .filter()
        .sessionIdIsNotNull()
        .sortByDateDesc()
        .findAll();

    final exercises = sets.map((set) => set.exerciseName).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final historyByExercise = <String, List<ExerciseSet>>{};
    for (final set in sets) {
      historyByExercise.putIfAbsent(set.exerciseName, () => []).add(set);
    }

    String? selected = widget.initialExercise;
    if (selected == null || !exercises.contains(selected)) {
      selected = exercises.isNotEmpty ? exercises.first : null;
    }

    final history = selected == null
        ? <ExerciseSet>[]
        : historyByExercise[selected] ?? <ExerciseSet>[];

    if (!mounted) return;
    setState(() {
      _availableExercises = exercises;
      _selectedExercise = selected;
      _history = history;
      _historyByExercise = historyByExercise;
      _isLoading = false;
    });
  }

  void _selectExercise(String? value) {
    if (value == null) return;
    setState(() {
      _selectedExercise = value;
      _history = _historyByExercise[value] ?? <ExerciseSet>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.utilities.toUpperCase(),
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
                      l10n.loads,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableExercises.isEmpty
              ? _EmptyWorkoutData(l10n: l10n)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _ReadOnlyBanner(colorScheme: colorScheme),
                    const SizedBox(height: 16),
                    _ExerciseSelector(
                      selectedExercise: _selectedExercise,
                      availableExercises: _availableExercises,
                      onChanged: _selectExercise,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 20),
                    _OverviewCards(history: _history, l10n: l10n),
                    const SizedBox(height: 24),
                    if (_sessionMaxHistory.length >= 2) ...[
                      _ChartSection(
                        sets: _sessionMaxHistory,
                        colorScheme: colorScheme,
                        l10n: l10n,
                        title: _selectedExercise ?? l10n.loadEvolution,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _HistoryList(history: _history, l10n: l10n),
                  ],
                ),
    );
  }

  List<ExerciseSet> get _sessionMaxHistory {
    return _bestSetPerSession(_history);
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ReadOnlyBanner({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.visibility_rounded,
                color: Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Apenas visualizacao: os dados vêm dos treinos registados no ecra de treino.',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.72),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSelector extends StatelessWidget {
  final String? selectedExercise;
  final List<String> availableExercises;
  final ValueChanged<String?> onChanged;
  final AppLocalizations l10n;

  const _ExerciseSelector({
    required this.selectedExercise,
    required this.availableExercises,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedExercise,
          hint: Text(l10n.selectExercise),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: availableExercises
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _OverviewCards extends StatelessWidget {
  final List<ExerciseSet> history;
  final AppLocalizations l10n;

  const _OverviewCards({required this.history, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final bestWeight = _bestWeightSet;
    final bestVolume = _bestVolumeSet;
    final latest = history.isNotEmpty ? history.first : null;
    final sessions =
        history.map((set) => set.sessionId).whereType<String>().toSet().length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.fitness_center_rounded,
                label: 'Melhor carga',
                value:
                    bestWeight == null ? '-' : '${_fmt(bestWeight.weight)} kg',
                detail: bestWeight == null
                    ? l10n.noHistoryYet
                    : '${bestWeight.reps} ${l10n.reps.toLowerCase()}',
                color: const Color(0xFF00E676),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.stacked_line_chart_rounded,
                label: l10n.workoutHistoryVolume,
                value: bestVolume == null
                    ? '-'
                    : _fmt(bestVolume.weight * bestVolume.reps),
                detail: bestVolume == null
                    ? l10n.noHistoryYet
                    : '${_fmt(bestVolume.weight)} kg x ${bestVolume.reps}',
                color: Colors.indigoAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.timeline_rounded,
                label: l10n.sessionTotalSets,
                value: history.length.toString(),
                detail: '$sessions ${l10n.session.toLowerCase()}',
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.update_rounded,
                label: l10n.lastSession,
                value: latest == null ? '-' : '${_fmt(latest.weight)} kg',
                detail: latest == null
                    ? l10n.noHistoryYet
                    : DateFormat('dd MMM', l10n.localeName).format(latest.date),
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  ExerciseSet? get _bestWeightSet {
    if (history.isEmpty) return null;
    return history.reduce((a, b) {
      if (b.weight > a.weight) return b;
      if (b.weight == a.weight && b.reps > a.reps) return b;
      return a;
    });
  }

  ExerciseSet? get _bestVolumeSet {
    if (history.isEmpty) return null;
    return history.reduce((a, b) {
      final aVolume = a.weight * a.reps;
      final bVolume = b.weight * b.reps;
      return bVolume > aVolume ? b : a;
    });
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 14),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.52),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final List<ExerciseSet> sets;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  final String title;

  const _ChartSection({
    required this.sets,
    required this.colorScheme,
    required this.l10n,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final spots = sets.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final weights = sets.map((set) => set.weight);
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = ((maxWeight - minWeight).abs() * 0.2).clamp(2.0, 20.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlockTitle(
            icon: Icons.show_chart_rounded,
            title: title,
            color: const Color(0xFF00E676),
          ),
          const SizedBox(height: 6),
          Text(
            'Cada ponto representa a melhor serie dessa sessao.',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                minY: (minWeight - padding).clamp(0.0, double.infinity),
                maxY: maxWeight + padding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (items) => items.map((item) {
                      final set = sets[item.x.toInt()];
                      return LineTooltipItem(
                        '${_fmt(set.weight)} kg x ${set.reps}\n${DateFormat('dd MMM', l10n.localeName).format(set.date)}',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: const Color(0xFF00E676),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: colorScheme.surface,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF00E676),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E676).withValues(alpha: 0.2),
                          const Color(0xFF00E676).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

class _HistoryList extends StatelessWidget {
  final List<ExerciseSet> history;
  final AppLocalizations l10n;

  const _HistoryList({required this.history, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BlockTitle(
          icon: Icons.history_rounded,
          title: l10n.recentHistory,
          color: Colors.indigoAccent,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final set = history[index];
            final volume = set.weight * set.reps;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: Color(0xFF00E676), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_fmt(set.weight)} kg x ${set.reps}',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy - HH:mm', l10n.localeName)
                              .format(set.date),
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.45),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(volume),
                        style: const TextStyle(
                          color: Colors.indigoAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        l10n.workoutHistoryVolume.toLowerCase(),
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BlockTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _BlockTitle({
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyWorkoutData extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyWorkoutData({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Color(0xFF00E676), size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.workoutHistoryEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.workoutHistoryEmptySub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ExerciseSet> _bestSetPerSession(List<ExerciseSet> history) {
  final bySession = <String, ExerciseSet>{};
  for (final set in history) {
    final key = set.sessionId ?? DateFormat('yyyy-MM-dd').format(set.date);
    final current = bySession[key];
    if (current == null ||
        set.weight > current.weight ||
        (set.weight == current.weight && set.reps > current.reps)) {
      bySession[key] = set;
    }
  }

  return bySession.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

String _fmt(double value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
