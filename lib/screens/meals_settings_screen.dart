import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../data/models/user.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/cloud_sync_service.dart';
import '../utils/constants.dart';

class MealsSettingsScreen extends ConsumerStatefulWidget {
  const MealsSettingsScreen({super.key});

  @override
  ConsumerState<MealsSettingsScreen> createState() =>
      _MealsSettingsScreenState();
}

class _MealsSettingsScreenState extends ConsumerState<MealsSettingsScreen> {
  late List<String> _meals;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _meals = List<String>.from(ref.read(mealOrderProvider));
      _initialized = true;
    }
  }

  Future<void> _persist() async {
    final db = ref.read(databaseProvider);
    await db.isar.writeTxn(() async {
      final user =
          await db.isar.userSettings.where().findFirst() ?? UserSettings();
      user.customMealOrder = List<String>.from(_meals);
      await db.isar.userSettings.put(user);
    });
    CloudSyncService(db).syncUserSettings();
  }

  Future<void> _addMeal(AppLocalizations l10n) async {
    final name = await _nameDialog('', l10n.mealNew, l10n);
    if (name == null || name.trim().isEmpty) return;
    setState(() => _meals.add(name.trim()));
    await _persist();
  }

  Future<void> _editMeal(int index, AppLocalizations l10n) async {
    final name = await _nameDialog(_meals[index], l10n.mealEditTitle, l10n);
    if (name == null || name.trim().isEmpty) return;
    setState(() => _meals[index] = name.trim());
    await _persist();
  }

  Future<void> _deleteMeal(int index, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mealDeleteTitle),
        content: Text(l10n.mealDeleteMsg(_meals[index])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelAction)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.deleteTooltip,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _meals.removeAt(index));
    await _persist();
  }

  Future<void> _resetToDefaults(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mealResetTitle),
        content: Text(l10n.mealResetMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelAction)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.mealRestoreAction,
                  style: const TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _meals = List<String>.from(AppConstants.mealOrder));

    final db = ref.read(databaseProvider);
    await db.isar.writeTxn(() async {
      final user =
          await db.isar.userSettings.where().findFirst() ?? UserSettings();
      user.customMealOrder = [];
      await db.isar.userSettings.put(user);
    });
    CloudSyncService(db).syncUserSettings();
  }

  Future<String?> _nameDialog(
      String initial, String title, AppLocalizations l10n) {
    final ctrl = TextEditingController(text: initial);
    final cs = Theme.of(context).colorScheme;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l10n.mealNameHint,
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: cs.primary, width: 2)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelAction)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(l10n.saveAction)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.meals),
        actions: [
          TextButton(
            onPressed: () => _resetToDefaults(l10n),
            child: Text(l10n.mealSettingsReset,
                style: TextStyle(color: cs.primary, fontSize: 13)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeal(l10n),
        backgroundColor: cs.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.mealSettingsAdd,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: cs.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.mealSettingsInfo,
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7), fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              itemCount: _meals.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _meals.removeAt(oldIndex);
                  _meals.insert(newIndex, item);
                });
                _persist();
              },
              proxyDecorator: (child, index, animation) => Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                shadowColor: cs.primary.withOpacity(0.3),
                child: child,
              ),
              itemBuilder: (context, index) {
                final meal = _meals[index];
                final isOnly = _meals.length == 1;
                return Card(
                  key: ValueKey('$meal-$index'),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  color: cs.surface,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    title: Text(meal,
                        style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: cs.onSurface.withOpacity(0.45), size: 20),
                          onPressed: () => _editMeal(index, l10n),
                          tooltip: l10n.editTooltip,
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: isOnly
                                  ? cs.onSurface.withOpacity(0.15)
                                  : Colors.redAccent.withOpacity(0.7),
                              size: 20),
                          onPressed:
                              isOnly ? null : () => _deleteMeal(index, l10n),
                          tooltip: isOnly ? null : l10n.deleteTooltip,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_handle_rounded,
                              color: cs.onSurface.withOpacity(0.3), size: 22),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
