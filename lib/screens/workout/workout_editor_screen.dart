import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/cloud_sync_service.dart';
import '../../utils/app_toast.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'exercise_picker_screen.dart';
import 'workout_templates.dart';

class EditorSession {
  WorkoutDay day;
  List<WorkoutExercise> exercises;

  EditorSession(this.day, this.exercises);
}

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final WorkoutPlan? plan;
  final WorkoutTemplate? template;
  const WorkoutEditorScreen({super.key, this.plan, this.template});

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen>
    with TickerProviderStateMixin {
  late TextEditingController _planNameController;
  TabController? _tabController;

  final List<EditorSession> _sessions = [];
  bool _isLoading = true;

  final Set<int> _originalDayIds = {};
  final Set<int> _originalExerciseIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _planNameController = TextEditingController(text: widget.plan!.name);
      _loadExistingPlan();
    } else if (widget.template != null) {
      _planNameController =
          TextEditingController(text: widget.template!.name);
      _loadFromTemplate(widget.template!);
    } else {
      _planNameController = TextEditingController(text: '');
      _sessions.add(EditorSession(WorkoutDay()..name = 'A', []));
      _isLoading = false;
      _initTabController();
    }
  }

  void _loadFromTemplate(WorkoutTemplate template) {
    for (final td in template.days) {
      final exercises = td.exercises.map((te) {
        return WorkoutExercise()
          ..name = te.name
          ..sets = te.sets
          ..reps = te.reps
          ..weight = 0;
      }).toList();
      _sessions.add(EditorSession(WorkoutDay()..name = td.name, exercises));
    }
    _isLoading = false;
    _initTabController();
  }

  Future<void> _loadExistingPlan() async {
    await widget.plan!.days.load();
    for (var day in widget.plan!.days) {
      await day.exercises.load();
      _originalDayIds.add(day.id);
      _originalExerciseIds.addAll(day.exercises.map((e) => e.id));
      _sessions.add(EditorSession(day, day.exercises.toList()));
    }

    if (_sessions.isEmpty) {
      _sessions.add(EditorSession(WorkoutDay()..name = 'A', []));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _initTabController();
      });
    }
  }

  void _initTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: _sessions.length, vsync: this);
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _addSession(AppLocalizations l10n) {
    setState(() {
      _sessions.add(EditorSession(
        WorkoutDay()
          ..name = '${l10n.workoutSessionDefault} ${_sessions.length + 1}',
        [],
      ));
      _initTabController();
      _tabController?.animateTo(_sessions.length - 1);
    });
  }

  void _removeCurrentSession(AppLocalizations l10n) {
    if (_sessions.length <= 1) {
      AppToast.show(context, l10n.workoutMinDays, isError: true);
      return;
    }
    setState(() {
      int index = _tabController!.index;
      _sessions.removeAt(index);
      _initTabController();
      if (index > 0) {
        _tabController?.animateTo(index - 1);
      }
    });
  }

  void _renameSession(int index, AppLocalizations l10n) {
    final controller = TextEditingController(text: _sessions[index].day.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.workoutNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sessions[index].day.name = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: Text(l10n.save,
                style: const TextStyle(
                    color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise(int sessionIndex) async {
    final name = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        _sessions[sessionIndex].exercises.add(WorkoutExercise()
          ..name = name
          ..sets = 3
          ..reps = '10'
          ..weight = 0);
      });
    }
  }

  Future<void> _exportToPdf(AppLocalizations l10n) async {
    if (_sessions.isEmpty) return;
    final doc = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          margin: const pw.EdgeInsets.all(40),
        ),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_planNameController.text,
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('GymOS',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ];

          for (final session in _sessions) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    vertical: 5, horizontal: 10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(session.day.name,
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));
            widgets.add(
              pw.TableHelper.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.white),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },
                data: <List<String>>[
                  <String>[
                    l10n.exerciseName,
                    l10n.sets,
                    l10n.reps,
                    l10n.weightKg,
                  ],
                  ...session.exercises.map((e) => [
                        e.name,
                        e.sets.toString(),
                        e.reps,
                        e.weight > 0 ? '${e.weight}kg' : '-',
                      ]),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(pw.Divider(color: PdfColors.grey300));
            widgets.add(pw.SizedBox(height: 20));
          }

          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20),
              child: pw.Center(
                  child: pw.Text(l10n.workoutPdfFooter,
                      style: const pw.TextStyle(
                          color: PdfColors.grey500, fontSize: 10))),
            ),
          );

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${_planNameController.text}_Treino.pdf',
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_planNameController.text.isEmpty) {
      AppToast.show(context, l10n.workoutNameRequired, isError: true);
      return;
    }
    if (_isLoading) return;

    final db = ref.read(databaseProvider);
    final plan = widget.plan ?? WorkoutPlan();
    plan.name = _planNameController.text.trim();
    plan.lastUpdated = DateTime.now();

    try {
      await db.isar.writeTxn(() async {
        final currentDayIds = _sessions.map((s) => s.day.id).toSet();
        final daysToDelete = _originalDayIds
            .where((id) => !currentDayIds.contains(id))
            .toList();

        final currentExerciseIds = <int>{};
        for (var s in _sessions) {
          currentExerciseIds.addAll(s.exercises.map((e) => e.id));
        }
        final exercisesToDelete = _originalExerciseIds
            .where((id) => !currentExerciseIds.contains(id))
            .toList();

        if (daysToDelete.isNotEmpty) {
          await db.isar.workoutDays.deleteAll(daysToDelete);
        }
        if (exercisesToDelete.isNotEmpty) {
          await db.isar.workoutExercises.deleteAll(exercisesToDelete);
        }

        for (var session in _sessions) {
          await db.isar.workoutExercises.putAll(session.exercises);
        }

        final days = _sessions.map((s) => s.day).toList();
        await db.isar.workoutDays.putAll(days);

        for (var session in _sessions) {
          session.day.exercises.clear();
          session.day.exercises.addAll(session.exercises);
          await session.day.exercises.save();
        }

        await db.isar.workoutPlans.put(plan);
        plan.days.clear();
        plan.days.addAll(days);
        await plan.days.save();
      });
      CloudSyncService(db).syncWorkoutPlan(plan);

      if (mounted) {
        AppToast.show(context, l10n.workoutSaveSuccess);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, '${l10n.workoutSaveError}: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _planNameController,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: l10n.workoutPlanNameHint,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _exportToPdf(l10n),
            tooltip: l10n.workoutExportPdf,
            icon: const Icon(Icons.print_rounded),
            style:
                IconButton.styleFrom(foregroundColor: colorScheme.onSurface),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 20),
              label: Text(l10n.save.toUpperCase()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _save(l10n),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF00E676),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00E676),
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          dividerColor: Colors.transparent,
          tabs: _sessions.map((s) => Tab(text: s.day.name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
            _sessions.length, (index) => _buildSessionPage(index, l10n)),
      ),
    );
  }

  Widget _buildSessionPage(int index, AppLocalizations l10n) {
    final session = _sessions[index];
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_view_week_rounded,
                    color: Color(0xFF00E676)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.session,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    GestureDetector(
                      onTap: () => _renameSession(index, l10n),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              session.day.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit,
                              size: 14,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF00E676)),
                tooltip: l10n.workoutNewSession,
                onPressed: () => _addSession(l10n),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                tooltip: l10n.workoutDeleteSession,
                onPressed: () => _removeCurrentSession(l10n),
              ),
            ],
          ),
        ),
        Expanded(
          child: session.exercises.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center,
                          size: 60,
                          color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 10),
                      Text(l10n.noExercises,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _addExercise(index),
                        icon: const Icon(Icons.search_rounded),
                        label: Text(l10n.workoutAddFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.surface,
                          foregroundColor: const Color(0xFF00E676),
                          elevation: 0,
                          side: const BorderSide(
                              color: Color(0xFF00E676)),
                        ),
                      )
                    ],
                  ),
                )
              : ReorderableListView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.transparent,
                      child: child,
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item =
                          session.exercises.removeAt(oldIndex);
                      session.exercises.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int i = 0;
                        i < session.exercises.length;
                        i++)
                      _buildExerciseCard(
                          session.exercises[i], index, i, l10n)
                  ],
                ),
        ),
        if (session.exercises.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -5),
                    blurRadius: 10)
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () => _addExercise(index),
                icon: const Icon(Icons.search_rounded),
                label: Text(l10n.addExerciseAction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00E676),
                  side: const BorderSide(
                      color: Color(0xFF00E676), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, int sessionIndex,
      int exIndex, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: ObjectKey(exercise),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(Icons.drag_handle_rounded,
                    color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 20),
                  onPressed: () {
                    setState(() {
                      _sessions[sessionIndex].exercises.remove(exercise);
                    });
                  },
                )
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniInput(
                    label: l10n.sets,
                    value: exercise.sets.toString(),
                    onChanged: (v) =>
                        exercise.sets = int.tryParse(v) ?? 3,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniInput(
                    label: l10n.reps,
                    value: exercise.reps,
                    onChanged: (v) => exercise.reps = v,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMiniInput(
                    label: l10n.weightKg,
                    value: exercise.weight > 0
                        ? exercise.weight.toString()
                        : '',
                    onChanged: (v) =>
                        exercise.weight = double.tryParse(v) ?? 0,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    isDark: isDark,
                    hint: '0',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniInput({
    required String label,
    required String value,
    required Function(String) onChanged,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
        ),
        TextFormField(
          initialValue: value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.withValues(alpha: 0.4)),
            isDense: true,
            filled: true,
            fillColor: isDark
                ? Colors.grey.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
