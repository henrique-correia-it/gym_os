import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gym_os/l10n/app_localizations.dart'; // <--- Import Adicionado
import '../../data/models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/cloud_sync_service.dart';
import '../../utils/app_toast.dart';

class LoadTrackerScreen extends ConsumerStatefulWidget {
  final String? initialExercise;
  const LoadTrackerScreen({super.key, this.initialExercise});

  @override
  ConsumerState<LoadTrackerScreen> createState() => _LoadTrackerScreenState();
}

class _LoadTrackerScreenState extends ConsumerState<LoadTrackerScreen> {
  String? _selectedExercise;
  List<ExerciseSet> _history = [];
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  List<String> _availableExercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedExercise = widget.initialExercise;
    _loadAvailableExercises();
    if (_selectedExercise != null) _loadHistory();
  }

  Future<void> _loadAvailableExercises() async {
    final db = ref.read(databaseProvider);
    final plans = await db.isar.workoutPlans.where().findAll();
    final names = <String>{};

    for (var plan in plans) {
      await plan.days.load();
      for (var day in plan.days) {
        await day.exercises.load();
        for (var ex in day.exercises) {
          names.add(ex.name);
        }
      }
    }

    if (mounted) {
      setState(() {
        _availableExercises = names.toList()..sort();
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_selectedExercise == null) return;
    final db = ref.read(databaseProvider);

    final results = await db.isar.exerciseSets
        .filter()
        .exerciseNameEqualTo(_selectedExercise!)
        .sortByDateDesc()
        .limit(50)
        .findAll();

    if (mounted) {
      setState(() => _history = results);
    }
  }

  void _saveSet() async {
    // 1. Obter l10n para usar nas mensagens de erro/sucesso
    final l10n = AppLocalizations.of(context)!;

    if (_selectedExercise == null) {
      AppToast.show(context, l10n.selectExercise, isError: true);
      return;
    }

    final weightText = _weightController.text.replaceAll(',', '.');
    final weight = double.tryParse(weightText) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    if (weight <= 0 || reps <= 0) {
      AppToast.show(context, l10n.required, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newSet = ExerciseSet()
        ..exerciseName = _selectedExercise!
        ..weight = weight
        ..reps = reps
        ..date = DateTime.now();

      final db = ref.read(databaseProvider);
      await db.isar.writeTxn(() async {
        await db.isar.exerciseSets.put(newSet);
      });
      CloudSyncService(db).syncExerciseSet(newSet);

      // Limpar campos
      _weightController.clear();
      _repsController.clear();

      // 2. Verificar mounted antes de usar context
      if (mounted) {
        FocusScope.of(context).unfocus();
      }

      await _loadHistory();

      if (mounted) AppToast.show(context, l10n.setSaved);
    } catch (e) {
      if (mounted) AppToast.show(context, "${l10n.error}: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 3. Obter l10n no método build
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.trending_up_rounded,
                  color: Colors.indigoAccent, size: 24),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4. Remover const e usar l10n
                Text(l10n.utilities,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(l10n.loads,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          children: [
            // 5. Passar l10n para os widgets filhos
            _buildExerciseSelector(colorScheme, l10n),
            const SizedBox(height: 20),
            if (_selectedExercise != null) ...[
              _buildInputCard(colorScheme, l10n),
              const SizedBox(height: 25),
              if (_history.length >= 2) ...[
                _buildChartSection(colorScheme, l10n),
                const SizedBox(height: 25),
              ],
              _buildHistoryList(colorScheme, l10n),
            ] else
              _buildEmptyState(colorScheme, l10n),
          ],
        ),
      ),
    );
  }

  // 6. Atualizar assinaturas dos métodos para receber l10n
  Widget _buildExerciseSelector(
      ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedExercise,
          hint: Text(l10n.selectExercise), // Traduzido
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: _availableExercises.map((name) {
            return DropdownMenuItem(value: name, child: Text(name));
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedExercise = val);
            _loadHistory();
          },
        ),
      ),
    );
  }

  Widget _buildInputCard(ColorScheme colorScheme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border:
            Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.newSet, // Traduzido e sem const
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBigInput(
                  controller: _weightController,
                  label: l10n.weightKg.toUpperCase(), // Traduzido
                  suffix: "kg",
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildBigInput(
                  controller: _repsController,
                  label: l10n.reps.toUpperCase(), // Traduzido
                  suffix: "",
                  colorScheme: colorScheme,
                  isInteger: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text(l10n.recordProgress, // Traduzido e sem const
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBigInput({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required ColorScheme colorScheme,
    bool isInteger = false,
  }) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
            height: 1.0,
          ),
          decoration: InputDecoration(
            hintText: "0",
            hintStyle:
                TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.1)),
            suffixText: suffix,
            suffixStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(ColorScheme colorScheme, AppLocalizations l10n) {
    // Filtrar para mostrar apenas o set mais pesado por sessão (dia) no gráfico
    final Map<String, ExerciseSet> sessionMaxWeights = {};
    for (var set in _history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(set.date);
      if (!sessionMaxWeights.containsKey(dateKey) ||
          set.weight > sessionMaxWeights[dateKey]!.weight) {
        sessionMaxWeights[dateKey] = set;
      }
    }

    final chartHistory = sessionMaxWeights.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = chartHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

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
          Text(l10n.loadEvolution, // Traduzido e sem const
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1)),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
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
                minY:
                    spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.9,
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

  Widget _buildHistoryList(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(l10n.recentHistory, // Traduzido e sem const
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1)),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          separatorBuilder: (c, i) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final set = _history[index];
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.05)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                title: Row(
                  children: [
                    Text("${set.weight} kg",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 8),
                    Text("× ${set.reps}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
                // 7. Data formatada com localeName
                subtitle: Text(
                    DateFormat('dd MMM • HH:mm', l10n.localeName)
                        .format(set.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    final db = ref.read(databaseProvider);
                    await db.isar
                        .writeTxn(() => db.isar.exerciseSets.delete(set.id));
                    CloudSyncService(db).deleteExerciseSet(set.id);
                    _loadHistory();
                    if (mounted) AppToast.show(context, l10n.recordDeleted);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.touch_app_rounded,
                size: 80, color: colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 20),
            Text(l10n.startBySelecting, // Traduzido e sem const
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
