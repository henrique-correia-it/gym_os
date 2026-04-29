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
                },
                data: <List<String>>[
                  <String>[
                    l10n.exerciseName,
                    l10n.sets,
                    l10n.reps,
                  ],
                  ...session.exercises.map((e) => [
                        e.name,
                        e.sets.toString(),
                        e.reps,
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(135),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _planNameController.text,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                              letterSpacing: -1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _exportToPdf(l10n),
                          tooltip: l10n.workoutExportPdf,
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 22),
                          style: IconButton.styleFrom(
                            foregroundColor:
                                colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E676), Color(0xFF00C853)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _save(l10n),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.black87,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_rounded, size: 16),
                                  const SizedBox(width: 4),
                                  Text(l10n.save,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF00E676),
                unselectedLabelColor:
                    colorScheme.onSurface.withValues(alpha: 0.4),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: Color(0xFF00E676),
                    width: 3,
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: _sessions
                    .map((s) => Tab(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(s.day.name),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
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
        // ── Session header ───────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _renameSession(index, l10n),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.session.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00E676),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              session.day.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildSessionActionBtn(
                icon: Icons.add_rounded,
                color: const Color(0xFF00E676),
                onTap: () => _addSession(l10n),
              ),
              const SizedBox(width: 7),
              _buildSessionActionBtn(
                icon: Icons.remove_rounded,
                color: Colors.redAccent,
                onTap: () => _removeCurrentSession(l10n),
              ),
            ],
          ),
        ),

        // ── Exercise list ────────────────────────────────────────────────
        Expanded(
          child: session.exercises.isEmpty
              ? _buildEmptyState(index, l10n)
              : ReorderableListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  proxyDecorator: (child, index, animation) => Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(18),
                    shadowColor: Colors.black38,
                    color: Colors.transparent,
                    child: child,
                  ),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = session.exercises.removeAt(oldIndex);
                      session.exercises.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int i = 0; i < session.exercises.length; i++)
                      _buildExerciseCard(session.exercises[i], index, i, l10n),
                  ],
                ),
        ),

        // ── Add exercise button ──────────────────────────────────────────
        if (session.exercises.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _addExercise(index),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.addExerciseAction,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(int sessionIndex, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded,
                size: 48, color: Color(0xFF00E676)),
          ),
          const SizedBox(height: 20),
          Text(l10n.noExercises,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(l10n.workoutAddFirst,
              style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _addExercise(sessionIndex),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(l10n.addExerciseAction,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise, int sessionIndex,
      int exIndex, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ObjectKey(exercise),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remover exercício'),
            content: Text('Remover "${exercise.name}" desta sessão?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        setState(() {
          _sessions[sessionIndex].exercises.remove(exercise);
        });
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Remover',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Number + drag handle ───────────────────────────────
                Container(
                  width: 46,
                  color: const Color(0xFF00E676).withValues(alpha: 0.08),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${exIndex + 1}',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.drag_handle_rounded,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),

                // ── Exercise content ───────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.sets,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(height: 4),
                                _buildSetsStepper(exercise, isDark),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildMiniInput(
                                label: l10n.reps,
                                value: exercise.reps,
                                onChanged: (v) => exercise.reps = v,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetsStepper(WorkoutExercise exercise, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (exercise.sets > 1) exercise.sets--;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Icon(Icons.remove_rounded,
                  size: 15,
                  color: exercise.sets > 1
                      ? Colors.grey
                      : Colors.grey.withValues(alpha: 0.25)),
            ),
          ),
          Text(
            '${exercise.sets}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          GestureDetector(
            onTap: () => setState(() => exercise.sets++),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Icon(Icons.add_rounded,
                  size: 15, color: Color(0xFF00E676)),
            ),
          ),
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
                  fontSize: 10,
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
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.4)),
            isDense: true,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
