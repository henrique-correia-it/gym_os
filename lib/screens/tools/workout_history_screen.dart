import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import '../../data/models/workout.dart';
import '../../providers/app_providers.dart';

const _kAccent = Colors.deepPurpleAccent;
const _kSessionGap = Duration(hours: 1);

class _SessionMeta {
  final String? planName;
  final String? dayName;
  _SessionMeta(this.planName, this.dayName);
}

class _WorkoutSession {
  final DateTime startTime;
  final List<ExerciseSet> sets;
  _SessionMeta meta;
  _WorkoutSession({required this.startTime, required this.sets, required this.meta});
}

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  List<_WorkoutSession> _sessions = [];
  bool _isLoading = true;
  final Set<DateTime> _expandedSessions = {};
  final Set<String> _expandedExercises = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final db = ref.read(databaseProvider);

    final allSets = await db.isar.exerciseSets.where().anyId().findAll();
    allSets.sort((a, b) => a.date.compareTo(b.date)); // chronological

    // Group by sessionId when available; fall back to time-gap for legacy records
    final sessions = <_WorkoutSession>[];
    final bySessionId = <String, List<ExerciseSet>>{};
    final legacySets = <ExerciseSet>[];

    for (final set in allSets) {
      if (set.sessionId != null) {
        bySessionId.putIfAbsent(set.sessionId!, () => []).add(set);
      } else {
        legacySets.add(set);
      }
    }

    // Sessions with explicit ID
    for (final entry in bySessionId.entries) {
      final sorted = entry.value..sort((a, b) => a.date.compareTo(b.date));
      sessions.add(_WorkoutSession(
        startTime: sorted.first.date,
        sets: sorted,
        meta: _SessionMeta(null, null),
      ));
    }

    // Legacy records: split by time gap
    List<ExerciseSet> current = [];
    for (final set in legacySets) {
      if (current.isEmpty ||
          set.date.difference(current.last.date) <= _kSessionGap) {
        current.add(set);
      } else {
        sessions.add(_WorkoutSession(
          startTime: current.first.date,
          sets: List.from(current),
          meta: _SessionMeta(null, null),
        ));
        current = [set];
      }
    }
    if (current.isNotEmpty) {
      sessions.add(_WorkoutSession(
        startTime: current.first.date,
        sets: List.from(current),
        meta: _SessionMeta(null, null),
      ));
    }

    // Newest first
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    // Build plan→day index for matching
    final plans = await db.isar.workoutPlans.where().anyId().findAll();
    final dayIndex =
        <int, ({String planName, String dayName, Set<String> names})>{};
    for (final plan in plans) {
      await plan.days.load();
      for (final day in plan.days) {
        await day.exercises.load();
        dayIndex[day.id] = (
          planName: plan.name,
          dayName: day.name,
          names: day.exercises.map((e) => e.name.toLowerCase()).toSet(),
        );
      }
    }

    // Match each session to best-fitting workout day
    for (final session in sessions) {
      final sessionNames =
          session.sets.map((s) => s.exerciseName.toLowerCase()).toSet();
      int bestScore = 0;
      _SessionMeta? bestMatch;
      for (final info in dayIndex.values) {
        final score = info.names.intersection(sessionNames).length;
        if (score > bestScore) {
          bestScore = score;
          bestMatch = _SessionMeta(info.planName, info.dayName);
        }
      }
      session.meta = bestMatch ?? _SessionMeta(null, null);
    }

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history_rounded,
                  color: _kAccent, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.utilities,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(l10n.workoutHistoryTitle,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState(colorScheme, l10n)
              : _buildBody(colorScheme, l10n),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final session = _sessions[index];
        return Dismissible(
          key: ValueKey(session.startTime.millisecondsSinceEpoch),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(session, l10n),
          onDismissed: (_) => _deleteSession(session),
          background: _buildSwipeBackground(),
          child: _buildSessionCard(session, colorScheme, l10n),
        );
      },
    );
  }

  Widget _buildSwipeBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.redAccent, size: 26),
            SizedBox(height: 4),
            Text('Apagar',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(_WorkoutSession session, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Apagar sessão?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Serão apagados ${session.sets.length} registo(s) desta sessão. Esta ação não pode ser desfeita.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteSession(_WorkoutSession session) async {
    final db = ref.read(databaseProvider);
    final ids = session.sets.map((s) => s.id).toList();
    await db.isar.writeTxn(() async {
      await db.isar.exerciseSets.deleteAll(ids);
    });
    setState(() => _sessions.remove(session));
  }

  Widget _buildEmptyState(ColorScheme colorScheme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_rounded,
                size: 80,
                color: colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 20),
            Text(l10n.workoutHistoryEmpty,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text(l10n.workoutHistoryEmptySub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      _WorkoutSession session, ColorScheme colorScheme, AppLocalizations l10n) {
    final isExpanded = _expandedSessions.contains(session.startTime);
    final meta = session.meta;

    final byExercise = <String, List<ExerciseSet>>{};
    for (final s in session.sets) {
      byExercise.putIfAbsent(s.exerciseName, () => []).add(s);
    }
    for (final v in byExercise.values) {
      v.sort((a, b) => a.date.compareTo(b.date));
    }

    final totalVolume =
        session.sets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDay = DateTime(session.startTime.year, session.startTime.month,
        session.startTime.day);

    String dateLabel;
    if (sessionDay == today) {
      dateLabel = l10n.today;
    } else if (sessionDay == yesterday) {
      final raw = l10n.yesterday;
      dateLabel = raw[0].toUpperCase() + raw.substring(1);
    } else {
      final raw = DateFormat('EEEE, d MMM', l10n.localeName).format(session.startTime);
      dateLabel = raw[0].toUpperCase() + raw.substring(1);
    }
    if (sessionDay.year != now.year) dateLabel += ' ${sessionDay.year}';

    final timeLabel = DateFormat('HH:mm').format(session.startTime);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isExpanded
                ? _kAccent.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kAccent, _kAccent.withValues(alpha: 0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                      onTap: () => setState(() {
                        if (isExpanded) {
                          _expandedSessions.remove(session.startTime);
                        } else {
                          _expandedSessions.add(session.startTime);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(dateLabel,
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      colorScheme.onSurface)),
                                          const SizedBox(width: 8),
                                          Text('• $timeLabel',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.4))),
                                        ],
                                      ),
                                      if (meta.planName != null) ...[
                                        const SizedBox(height: 5),
                                        _buildPlanBadge(
                                            meta.planName!, meta.dayName),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatChip(colorScheme,
                                    '${byExercise.length}',
                                    l10n.workoutHistoryExercises),
                                const SizedBox(width: 10),
                                _buildStatChip(colorScheme,
                                    '${session.sets.length}', l10n.sets),
                                const SizedBox(width: 10),
                                _buildStatChip(
                                    colorScheme,
                                    '${totalVolume.toStringAsFixed(0)} kg',
                                    l10n.workoutHistoryVolume),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    if (isExpanded) ...[
                      Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: colorScheme.outline.withValues(alpha: 0.12)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        child: Column(
                          children: byExercise.entries.indexed
                              .map((e) => _buildExerciseBlock(
                                  e.$2.key,
                                  e.$2.value,
                                  colorScheme,
                                  l10n,
                                  e.$1 < byExercise.length - 1))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanBadge(String planName, String? dayName) {
    final label = dayName != null ? '$dayName • $planName' : planName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 10, color: _kAccent),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kAccent),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      ColorScheme colorScheme, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildExerciseBlock(String name, List<ExerciseSet> sets,
      ColorScheme colorScheme, AppLocalizations l10n, bool showDivider) {
    final exerciseKey = '${sets.first.date.millisecondsSinceEpoch}_$name';
    final isExpanded = _expandedExercises.contains(exerciseKey);
    final volume = sets.fold<double>(0, (sum, s) => sum + s.weight * s.reps);
    final maxWeight =
        sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) {
              _expandedExercises.remove(exerciseKey);
            } else {
              _expandedExercises.add(exerciseKey);
            }
          }),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: _kAccent, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _buildMiniChip(colorScheme,
                              '${sets.length} ${l10n.sets.toLowerCase()}'),
                          const SizedBox(width: 6),
                          _buildMiniChip(colorScheme,
                              'max ${maxWeight.toStringAsFixed(maxWeight == maxWeight.roundToDouble() ? 0 : 1)} kg'),
                          const SizedBox(width: 6),
                          _buildMiniChip(colorScheme,
                              '${volume.toStringAsFixed(0)} kg vol'),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 42, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sets.indexed.map((e) {
                final i = e.$1;
                final s = e.$2;
                final vol = s.weight * s.reps;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _kAccent)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${s.weight.toStringAsFixed(s.weight == s.weight.roundToDouble() ? 0 : 1)} kg  ×  ${s.reps}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '= ${vol.toStringAsFixed(0)} kg',
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        if (showDivider)
          Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.08)),
      ],
    );
  }

  Widget _buildMiniChip(ColorScheme colorScheme, String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.5)));
  }
}
