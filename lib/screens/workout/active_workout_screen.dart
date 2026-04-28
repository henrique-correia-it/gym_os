import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../data/models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/cloud_sync_service.dart';
import '../../utils/app_toast.dart';

// ── In-memory set logged during this session ─────────────────────────────────
class _SessionSet {
  final int id;
  double weight;
  int reps;
  _SessionSet({required this.id, required this.weight, required this.reps});
}

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final WorkoutPlan plan;
  final WorkoutDay day;

  const ActiveWorkoutScreen({
    super.key,
    required this.plan,
    required this.day,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  // ── Exercises ────────────────────────────────────────────────────────────
  List<WorkoutExercise> _exercises = [];
  bool _loading = true;
  int _currentIndex = 0;

  // ── Session timer ────────────────────────────────────────────────────────
  int _sessionSeconds = 0;
  Timer? _sessionTimer;

  // ── Sets logged this session: exerciseId → list ──────────────────────────
  final Map<int, List<_SessionSet>> _sessionSets = {};
  final String _sessionId =
      DateTime.now().millisecondsSinceEpoch.toString();

  // ── Previous history: exerciseId → recent ExerciseSets ──────────────────
  final Map<int, List<ExerciseSet>> _history = {};

  // ── Rest timer ───────────────────────────────────────────────────────────
  int _restRemaining = 0;
  bool _restActive = false;
  Timer? _restTimer;
  int _restDuration = 90;

  // ── Inputs ───────────────────────────────────────────────────────────────
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();

  // ── PR feedback ──────────────────────────────────────────────────────────
  bool _showPR = false;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _loadExercises();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadExercises() async {
    await widget.day.exercises.load();
    final list = widget.day.exercises.toList();
    setState(() {
      _exercises = list;
      _loading = false;
    });
    if (list.isNotEmpty) {
      await _loadHistoryFor(list[0]);
      _prefillInputs(list[0]);
    }
  }

  Future<void> _loadHistoryFor(WorkoutExercise ex) async {
    if (_history.containsKey(ex.id)) return;
    final db = ref.read(databaseProvider);
    final sets = await db.isar.exerciseSets
        .filter()
        .exerciseNameEqualTo(ex.name)
        .sortByDateDesc()
        .limit(15)
        .findAll();
    if (mounted) setState(() => _history[ex.id] = sets);
  }

  void _prefillInputs(WorkoutExercise ex) {
    final history = _history[ex.id] ?? [];
    if (history.isNotEmpty) {
      _weightCtrl.text = _formatWeight(history.first.weight);
      _repsCtrl.text = history.first.reps.toString();
    } else {
      _weightCtrl.text = ex.weight > 0 ? _formatWeight(ex.weight) : '';
      final firstNum =
          int.tryParse(ex.reps.split(RegExp(r'[-x×\s]')).first.trim()) ?? 0;
      _repsCtrl.text = firstNum > 0 ? firstNum.toString() : '';
    }
  }

  String _formatWeight(double w) =>
      w == w.truncateToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);

  // ── Session timer ─────────────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sessionSeconds++);
    });
  }

  String get _sessionTime {
    final m = _sessionSeconds ~/ 60;
    final s = _sessionSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Rest timer ────────────────────────────────────────────────────────────

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restRemaining = _restDuration;
      _restActive = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _restRemaining--;
        if (_restRemaining <= 0) {
          t.cancel();
          _restActive = false;
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() { _restActive = false; _restRemaining = 0; });
  }

  String get _restTime {
    final m = _restRemaining ~/ 60;
    final s = _restRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Logging ───────────────────────────────────────────────────────────────

  Future<void> _logSet() async {
    final l10n = AppLocalizations.of(context)!;
    if (_exercises.isEmpty) return;
    final ex = _exercises[_currentIndex];

    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsCtrl.text);

    if (weight == null || reps == null || weight <= 0 || reps <= 0) {
      AppToast.show(context, l10n.invalidSetInput, isError: true);
      return;
    }

    final db = ref.read(databaseProvider);
    final set = ExerciseSet()
      ..exerciseName = ex.name
      ..weight = weight
      ..reps = reps
      ..date = DateTime.now()
      ..sessionId = _sessionId;

    await db.isar.writeTxn(() async {
      await db.isar.exerciseSets.put(set);
    });
    CloudSyncService(db).syncExerciseSet(set);

    _sessionSets.putIfAbsent(ex.id, () => [])
        .add(_SessionSet(id: set.id, weight: weight, reps: reps));

    // Check PR
    final isPR = await _checkPR(ex.name, weight);

    // Reload history for updated display
    _history.remove(ex.id);
    await _loadHistoryFor(ex);

    _startRestTimer();

    if (isPR && mounted) {
      setState(() => _showPR = true);
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showPR = false);
      });
    }
  }

  Future<void> _editSessionSet(WorkoutExercise ex, _SessionSet s) async {
    final weightCtrl = TextEditingController(text: _formatWeight(s.weight));
    final repsCtrl = TextEditingController(text: s.reps.toString());
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(l10n.editSet,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.weight,
                        suffixText: 'kg',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.reps,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.save,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final newWeight = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
    final newReps = int.tryParse(repsCtrl.text);
    if (newWeight == null || newReps == null || newWeight <= 0 || newReps <= 0) return;

    final db = ref.read(databaseProvider);
    final stored = await db.isar.exerciseSets.get(s.id);
    if (stored == null) return;
    stored.weight = newWeight;
    stored.reps = newReps;
    await db.isar.writeTxn(() async => db.isar.exerciseSets.put(stored));
    CloudSyncService(db).syncExerciseSet(stored);

    setState(() {
      s.weight = newWeight;
      s.reps = newReps;
    });

    _history.remove(ex.id);
    await _loadHistoryFor(ex);
  }

  Future<void> _deleteSessionSet(WorkoutExercise ex, _SessionSet s) async {
    final db = ref.read(databaseProvider);
    await db.isar.writeTxn(() async => db.isar.exerciseSets.delete(s.id));

    setState(() {
      _sessionSets[ex.id]?.remove(s);
    });

    _history.remove(ex.id);
    await _loadHistoryFor(ex);
  }

  Future<bool> _checkPR(String name, double weight) async {
    final db = ref.read(databaseProvider);
    final all = await db.isar.exerciseSets
        .filter()
        .exerciseNameEqualTo(name)
        .sortByDateDesc()
        .findAll();
    // Skip the set we just logged (most recent); need at least one prior set
    if (all.length <= 1) return false;
    final previous = all.skip(1);
    final maxPrev = previous.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
    return weight > maxPrev;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _goTo(int index) async {
    _skipRest();
    setState(() => _currentIndex = index);
    final ex = _exercises[index];
    await _loadHistoryFor(ex);
    _prefillInputs(ex);
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.confirmFinishTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.confirmFinishMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.finishWorkout,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  void _finishWorkout() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _showSummary();
  }

  void _showSummary() {
    final l10n = AppLocalizations.of(context)!;
    int totalSets = 0;
    double totalVolume = 0;
    for (final sets in _sessionSets.values) {
      totalSets += sets.length;
      for (final s in sets) { totalVolume += s.weight * s.reps; }
    }
    final min = _sessionSeconds ~/ 60;
    final sec = _sessionSeconds % 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          top: 12, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                    blurRadius: 20, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(l10n.sessionDoneTitle,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                _SummaryChip(
                  icon: Icons.fitness_center_rounded,
                  label: l10n.sessionTotalSets,
                  value: '$totalSets',
                  color: Colors.purpleAccent,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.monitor_weight_outlined,
                  label: l10n.sessionTotalVolume,
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  icon: Icons.timer_outlined,
                  label: l10n.sessionDuration,
                  value: '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                  color: const Color(0xFF00E676),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(l10n.sessionClose,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.day.name),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center_rounded,
                  size: 64, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(l10n.noExercises,
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final ex = _exercises[_currentIndex];
    final sessionSets = _sessionSets[ex.id] ?? [];
    final history = _history[ex.id] ?? [];
    final lastSessionSets = _getLastSessionSets(history);
    final isLast = _currentIndex == _exercises.length - 1;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n, colorScheme),
              if (_restActive) _buildRestBanner(l10n),
              if (_showPR) _buildPRBanner(l10n),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentIndex),
                    child: _buildExerciseCard(
                        context, l10n, colorScheme, ex,
                        sessionSets, lastSessionSets),
                  ),
                ),
              ),
              _buildInputSection(l10n, colorScheme, ex),
              _buildNavBar(l10n, colorScheme, isLast),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppLocalizations l10n, ColorScheme cs) {
    final progress = (_currentIndex + 1) / _exercises.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Close button
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  if (!context.mounted) return;
                  final nav = Navigator.of(context);
                  final should = await _onWillPop();
                  if (should && context.mounted) nav.pop();
                },
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.5),
                    ),
                    Text(
                      widget.day.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Session timer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 14,
                        color: cs.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(_sessionTime,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: cs.onSurface.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Progress bar
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (ctx, value, _) => LinearProgressIndicator(
            value: value,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
            minHeight: 3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activeWorkoutOf(
                    (_currentIndex + 1).toString(), _exercises.length.toString()),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.45)),
              ),
              // Rest duration adjustment
              GestureDetector(
                onTap: _showRestAdjuster,
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty_rounded,
                        size: 12,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 3),
                    Text(
                      '${_restDuration}s',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Rest banner ───────────────────────────────────────────────────────────

  Widget _buildRestBanner(AppLocalizations l10n) {
    final ratio = _restDuration > 0 ? _restRemaining / _restDuration : 0.0;
    final color = ratio > 0.5
        ? const Color(0xFF00E676)
        : ratio > 0.25
            ? Colors.orangeAccent
            : Colors.redAccent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Text(l10n.restLabel,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 14)),
          const SizedBox(width: 8),
          Text(_restTime,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const Expanded(child: SizedBox()),
          TextButton(
            onPressed: _skipRest,
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.skipRest,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── PR banner ─────────────────────────────────────────────────────────────

  Widget _buildPRBanner(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Text(l10n.newPR,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.amber)),
        ],
      ),
    );
  }

  // ── Exercise card ─────────────────────────────────────────────────────────

  Widget _buildExerciseCard(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
    WorkoutExercise ex,
    List<_SessionSet> sessionSets,
    List<ExerciseSet> lastSessionSets,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Exercise name ────────────────────────────────────────────────
          Text(
            ex.name,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
          ),
          const SizedBox(height: 6),
          // ── Planned ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${l10n.planned}: ${ex.sets}× ${ex.reps}'
                  '${ex.weight > 0 ? ' @ ${_formatWeight(ex.weight)}kg' : ''}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purpleAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Last session ─────────────────────────────────────────────────
          _buildLastSession(l10n, cs, lastSessionSets),
          const SizedBox(height: 14),

          // ── This session sets ────────────────────────────────────────────
          if (sessionSets.isNotEmpty) ...[
            Text(l10n.setsThisSession,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: cs.onSurface.withValues(alpha: 0.4))),
            const SizedBox(height: 8),
            ...sessionSets.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00E676))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_formatWeight(s.weight)} kg  ×  ${s.reps} reps',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _editSessionSet(ex, s),
                      child: Icon(Icons.edit_rounded,
                          size: 16,
                          color: cs.onSurface.withValues(alpha: 0.35)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _deleteSessionSet(ex, s),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.redAccent.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildLastSession(
      AppLocalizations l10n, ColorScheme cs, List<ExerciseSet> sets) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 13,
                  color: cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 5),
              Text(l10n.lastSession,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: cs.onSurface.withValues(alpha: 0.4))),
              if (sets.isNotEmpty) ...[
                const Spacer(),
                Text(
                  _formatDate(sets.first.date, l10n),
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (sets.isEmpty)
            Text(l10n.noHistoryYet,
                style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: sets.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: cs.onSurface.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    '${_formatWeight(s.weight)}kg × ${s.reps}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ── Input section ─────────────────────────────────────────────────────────

  Widget _buildInputSection(
      AppLocalizations l10n, ColorScheme cs, WorkoutExercise ex) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            top: BorderSide(color: cs.onSurface.withValues(alpha: 0.07))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ── Weight ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.loadTrackerWeight,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: cs.onSurface.withValues(alpha: 0.45))),
                    const SizedBox(height: 6),
                    _buildNumericInput(
                      controller: _weightCtrl,
                      hint: '0.0',
                      suffix: 'kg',
                      decimal: true,
                      onMinus: () => _adjustValue(_weightCtrl, -2.5, decimal: true),
                      onPlus: () => _adjustValue(_weightCtrl, 2.5, decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Reps ────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.loadTrackerReps,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: cs.onSurface.withValues(alpha: 0.45))),
                    const SizedBox(height: 6),
                    _buildNumericInput(
                      controller: _repsCtrl,
                      hint: '0',
                      suffix: 'reps',
                      decimal: false,
                      onMinus: () => _adjustValue(_repsCtrl, -1, decimal: false),
                      onPlus: () => _adjustValue(_repsCtrl, 1, decimal: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Log button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                    blurRadius: 12, offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _logSet,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.logSet,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericInput({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required bool decimal,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _AdjustBtn(icon: Icons.remove_rounded, onTap: onMinus),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.25),
                    fontWeight: FontWeight.normal),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Text(suffix,
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          _AdjustBtn(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }

  void _adjustValue(TextEditingController ctrl, double delta,
      {required bool decimal}) {
    final current = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
    final next = (current + delta).clamp(0, 9999).toDouble();
    if (decimal) {
      ctrl.text = next == next.truncateToDouble()
          ? next.toInt().toString()
          : next.toStringAsFixed(1);
    } else {
      ctrl.text = next.round().toString();
    }
  }

  // ── Nav bar ───────────────────────────────────────────────────────────────

  Widget _buildNavBar(
      AppLocalizations l10n, ColorScheme cs, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          if (_currentIndex > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                  side: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _goTo(_currentIndex - 1),
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                label: Text(l10n.prevExercise,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isLast
                    ? const Color(0xFF00E676)
                    : cs.primaryContainer,
                foregroundColor: isLast
                    ? Colors.black
                    : cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: isLast
                  ? _finishWorkout
                  : () => _goTo(_currentIndex + 1),
              icon: Icon(
                isLast
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 16,
              ),
              label: Text(
                isLast ? l10n.finishWorkout : l10n.nextExercise,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rest adjuster ─────────────────────────────────────────────────────────

  void _showRestAdjuster() {
    final options = [30, 60, 90, 120, 180, 240, 300];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.restAdjust,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((sec) {
                  final selected = sec == _restDuration;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _restDuration = sec);
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
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
                      child: Text(
                        sec < 60
                            ? '${sec}s'
                            : '${sec ~/ 60}min${sec % 60 > 0 ? " ${sec % 60}s" : ""}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: selected
                              ? const Color(0xFF00E676)
                              : Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<ExerciseSet> _getLastSessionSets(List<ExerciseSet> history) {
    if (history.isEmpty) return [];
    final latest = history.first.date;
    final latestDay =
        DateTime(latest.year, latest.month, latest.day);
    return history
        .where((s) =>
            DateTime(s.date.year, s.date.month, s.date.day) == latestDay)
        .toList();
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    if (diff < 7) return l10n.daysAgo(diff);
    return DateFormat('dd/MM').format(date);
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _AdjustBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AdjustBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 52,
        alignment: Alignment.center,
        child: Icon(icon,
            size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45))),
          ],
        ),
      ),
    );
  }
}
