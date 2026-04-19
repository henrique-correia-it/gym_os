import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import '../../data/models/workout.dart';
import '../../providers/app_providers.dart';
import '../../services/cloud_sync_service.dart';
import '../../utils/app_toast.dart';
import 'workout_editor_screen.dart';
import 'active_workout_screen.dart';
import 'workout_templates.dart';

class WorkoutPlanListScreen extends ConsumerWidget {
  const WorkoutPlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.watch(databaseProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
     appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.fitness_center_rounded,
                  color: Color(0xFF00E676), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.navWorkout,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    )),
                Text(l10n.workoutSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    )),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<WorkoutPlan>>(
        stream: db.isar.workoutPlans.where().watch(fireImmediately: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!;

          if (plans.isEmpty) {
            return _buildEmptyState(context, l10n, colorScheme);
          }

          // padding.bottom already includes nav bar height (extendBody: true)
          final bottomPad = MediaQuery.of(context).padding.bottom;

          return Stack(
            fit: StackFit.expand,
            children: [
              ListView.separated(
                padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPad + 160),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Dismissible(
                key: Key(plan.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.white),
                ),
                confirmDismiss: (dir) => _confirmDelete(context, plan.name),
                onDismissed: (_) async {
                  await db.isar
                      .writeTxn(() => db.isar.workoutPlans.delete(plan.id));
                  CloudSyncService(db).deleteWorkoutPlan(plan.id);
                  if (context.mounted) AppToast.show(context, l10n.workoutDeleted);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => WorkoutEditorScreen(plan: plan))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 2),
                                Text(l10n.tapToEdit,
                                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _startWorkout(context, ref, plan),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(l10n.startWorkout,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
                },
              ),
              Positioned(
                bottom: bottomPad + 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 200,
                      child: FloatingActionButton.extended(
                        heroTag: 'templates_fab',
                        backgroundColor: Colors.purpleAccent.withValues(alpha: 0.85),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                        label: const Text('Templates',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        onPressed: () => _showTemplatePicker(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 200,
                      child: FloatingActionButton.extended(
                        heroTag: 'new_workout_fab',
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(l10n.newWorkout,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const WorkoutEditorScreen())),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, dynamic l10n, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Icon with glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E676).withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 46,
              color: Color(0xFF00E676),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.workoutEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.workoutEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 40),
          // Create from scratch card
          _EmptyActionCard(
            icon: Icons.add_rounded,
            iconColor: const Color(0xFF00E676),
            title: l10n.workoutEmptyCreateOwn,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutEditorScreen()),
            ),
          ),
          const SizedBox(height: 12),
          // Use template card
          _EmptyActionCard(
            icon: Icons.auto_awesome_rounded,
            iconColor: Colors.purpleAccent,
            title: l10n.workoutEmptyUseTemplate,
            onTap: () => _showTemplatePicker(context),
          ),
        ],
      ),
    );
  }

  // ── Start workout ─────────────────────────────────────────────────────────

  Future<void> _startWorkout(
      BuildContext context, WidgetRef ref, WorkoutPlan plan) async {
    await plan.days.load();
    final days = plan.days.toList();

    if (days.isEmpty) return;

    if (days.length == 1) {
      await days[0].exercises.load();
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ActiveWorkoutScreen(plan: plan, day: days[0]),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    _showDaySelector(context, plan, days);
  }

  void _showDaySelector(
      BuildContext context, WorkoutPlan plan, List<WorkoutDay> days) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color:
                            const Color(0xFF00E676).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.chooseTrainingDay,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(plan.name,
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
            const SizedBox(height: 24),
            Text(l10n.chooseTrainingDaySub,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
            const SizedBox(height: 12),
            ...days.map((day) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await day.exercises.load();
                      if (!ctx.mounted) return;
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActiveWorkoutScreen(plan: plan, day: day),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.fitness_center_rounded,
                                  size: 18, color: Colors.purpleAccent),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(day.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showTemplatePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutTemplatePicker(
        onUseTemplate: (template) async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutEditorScreen(template: template),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlanTitle),
        content: Text(l10n.deletePlanMessage(name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete,
                  style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}

class _EmptyActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _EmptyActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
