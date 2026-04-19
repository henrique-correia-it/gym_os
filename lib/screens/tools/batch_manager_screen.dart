import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/nutrition.dart';
import '../../providers/app_providers.dart';
import '../../services/cloud_sync_service.dart';
import '../../utils/app_toast.dart';
import 'batch_calculator_screen.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class BatchManagerScreen extends ConsumerWidget {
  const BatchManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_note_rounded,
                  color: Color(0xFF00E676), size: 28),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tools,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(l10n.batchManagerTitle,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: db.isar.foodItems
            .filter()
            .sourceEqualTo(l10n.sourceMarmita)
            .watch(fireImmediately: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(l10n.batchEmpty,
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return Dismissible(
                key: Key(item.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_sweep, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirm(context, item.name);
                },
                onDismissed: (direction) async {
                  final itemId = item.id;
                  final itemName = item.name;
                  await db.isar.writeTxn(() async {
                    await db.isar.foodItems.delete(itemId);
                  });
                  // Apaga também do Firebase para não reaparecer após restore
                  final cloudSync = CloudSyncService(db);
                  await cloudSync.deleteFood(itemId);
                  if (context.mounted) {
                    AppToast.show(context, l10n.foodDeleted(itemName));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.soup_kitchen_outlined,
                          color: Colors.blueAccent),
                    ),
                    title: Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                      "${item.kcal.toStringAsFixed(0)} kcal  •  ${item.protein.toStringAsFixed(1)}g P",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              BatchCalculatorScreen(existingMarmita: item),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.batchDeleteTitle),
        content: Text(l10n.batchDeleteConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete,
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
