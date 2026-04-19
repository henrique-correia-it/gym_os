import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import '../../data/models/user.dart';
import '../../providers/app_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/cloud_sync_service.dart';
import '../../utils/app_toast.dart';

class WeightHistoryScreen extends ConsumerStatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  ConsumerState<WeightHistoryScreen> createState() =>
      _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends ConsumerState<WeightHistoryScreen> {
  List<WeightEntry> _weightEntries = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final db = ref.read(databaseProvider);
    final logs = await db.isar.weightEntrys.where().sortByDateDesc().findAll();
    setState(() => _weightEntries = logs);
  }

  Widget _buildWeightChart() {
    if (_weightEntries.length < 2) return const SizedBox.shrink();

    final chartData = _weightEntries.reversed.toList();
    double minWeight =
        chartData.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 2;
    double maxWeight =
        chartData.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (chartData.length - 1).toDouble(),
          minY: minWeight,
          maxY: maxWeight,
          lineBarsData: [
            LineChartBarData(
              spots: chartData.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.weight);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF00E676),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00E676).withAlpha(80),
                    const Color(0xFF00E676).withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightModal() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    DateTime selectedDate = DateTime.now(); // SELETOR DE DATA ADICIONADO AQUI!

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            top: 20,
            left: 30,
            right: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),

              // --- BOTÃO DO CALENDÁRIO PARA ESCOLHER O DIA CORRETO ---
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF00E676),
                            onPrimary: Colors.black,
                            surface: Color(0xFF1E1E1E),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E676)),
                decoration: InputDecoration(
                  hintText: "00.00",
                  hintStyle: TextStyle(color: Colors.grey.withAlpha(50)),
                  suffixText: "kg",
                  suffixStyle:
                      const TextStyle(fontSize: 20, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => _saveWeight(controller.text,
                      selectedDate), // GUARDA PARA A DATA CERTA!
                  child: Text(l10n.confirmWeight,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  Future<void> _saveWeight(String value, DateTime selectedDate) async {
    final l10n = AppLocalizations.of(context)!;
    double? weight = double.tryParse(value.replaceAll(',', '.'));
    if (weight == null || weight <= 0) return;

    final db = ref.read(databaseProvider);
    final recordDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // Verifica se já existe um registo para este dia
    final existing = await db.isar.weightEntrys
        .filter()
        .dateEqualTo(recordDate)
        .findFirst();

    if (existing != null && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.duplicateWeightTitle),
          content: Text(l10n.duplicateWeightMessage(
              existing.weight.toStringAsFixed(2))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.replace,
                  style: const TextStyle(color: Color(0xFF00E676))),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    WeightEntry? updatedEntry;
    await db.isar.writeTxn(() async {
      var entry = existing ??
          (WeightEntry()
            ..date = recordDate
            ..weight = weight);
      entry.weight = weight;
      await db.isar.weightEntrys.put(entry);
      updatedEntry = entry;

      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (!recordDate.isBefore(today)) {
        final user = await db.isar.userSettings.where().findFirst();
        if (user != null) {
          user.weight = weight;
          await db.isar.userSettings.put(user);
        }
      }
    });

    if (updatedEntry != null) {
      CloudSyncService(db).syncWeightEntry(updatedEntry!);
    }

    if (!mounted) return;
    ref.invalidate(dashboardProvider);
    Navigator.pop(context);
    AppToast.show(context, l10n.updated);
    _loadLogs();
  }

  Future<void> _deleteWeight(WeightEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);
    final entryId = entry.id; // Guarda o ID antes de o objeto ser destruído!

    // 1. Apaga localmente
    await db.isar.writeTxn(() async {
      await db.isar.weightEntrys.delete(entryId);
    });

    // 2. Apaga na Nuvem IMEDIATAMENTE
    CloudSyncService(db).deleteWeightEntry(entryId);

    // 3. Pede ao Dashboard para recalcular (caso tenhas apagado o teu peso mais recente!)
    ref.invalidate(dashboardProvider);

    if (mounted) {
      AppToast.show(context, l10n.recordDeleted, isError: true);
    }

    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.show_chart,
                    color: Color(0xFF00E676), size: 28),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.evolution,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(l10n.weightAnalysis,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00E676),
        onPressed: _showAddWeightModal,
        label: Text(l10n.register,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
      body: _weightEntries.isEmpty
          ? Center(child: Text(l10n.noWeightRecords))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              children: [
                _buildWeightChart(),
                const SizedBox(height: 20),
                Text(l10n.recentHistory,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2)),
                const SizedBox(height: 15),
                ..._weightEntries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: Key(entry.id.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          final l10n = AppLocalizations.of(context)!;
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text(l10n.deleteWeightTitle),
                              content: Text(l10n.deleteWeightMessage(
                                  DateFormat('dd MMM yyyy', l10n.localeName)
                                      .format(entry.date))),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l10n.delete,
                                      style: const TextStyle(
                                          color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _deleteWeight(entry),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 25),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withAlpha(40),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withAlpha(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      DateFormat(
                                              'dd MMM, yyyy', l10n.localeName)
                                          .format(entry.date),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                      DateFormat('EEEE', l10n.localeName)
                                          .format(entry.date)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              Text("${entry.weight.toStringAsFixed(2)} kg",
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00E676))),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
