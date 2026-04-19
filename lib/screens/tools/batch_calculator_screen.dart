import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/nutrition.dart';
import '../../providers/app_providers.dart';
import '../../utils/text_normalize.dart';
import '../../services/cloud_sync_service.dart';
import '../../utils/app_toast.dart';
import '../../l10n/app_localizations.dart';

class BatchCalculatorScreen extends ConsumerStatefulWidget {
  final FoodItem? existingMarmita;
  const BatchCalculatorScreen({super.key, this.existingMarmita});

  @override
  ConsumerState<BatchCalculatorScreen> createState() =>
      _BatchCalculatorScreenState();
}

class _BatchCalculatorScreenState extends ConsumerState<BatchCalculatorScreen> {
  final List<MealEntry> _ingredients = [];
  final Set<int> _originalIngredientIds = {};
  double _numMarmitas = 1;
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMarmita != null) {
      _nameController =
          TextEditingController(text: widget.existingMarmita!.name);
      _numMarmitas = widget.existingMarmita!.portions;
      if (_numMarmitas <= 0) _numMarmitas = 1;
      _loadIngredients();
    } else {
      _nameController = TextEditingController();
    }
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    await widget.existingMarmita!.ingredients.load();
    if (mounted) {
      setState(() {
        _ingredients.addAll(widget.existingMarmita!.ingredients);
        _originalIngredientIds.addAll(_ingredients.map((e) => e.id));
        _isLoading = false;
      });
    }
  }

  double get _totalKcal => _ingredients.fold(0, (sum, item) => sum + item.kcal);
  double get _totalProt =>
      _ingredients.fold(0, (sum, item) => sum + item.protein);
  double get _totalCarb =>
      _ingredients.fold(0, (sum, item) => sum + item.carbs);
  double get _totalFat => _ingredients.fold(0, (sum, item) => sum + item.fat);

  void _addIngredient() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (context) => _IngredientSearchModal(onSelect: (food, amount) {
        double ratio = (food.unit == 'un') ? amount : (amount / 100.0);
        setState(() {
          _ingredients.add(MealEntry()
            ..foodName = food.name
            ..amount = amount
            ..type = l10n.ingredientType
            ..unit = food.unit
            ..baseKcal = food.kcal
            ..baseProtein = food.protein
            ..baseCarbs = food.carbs
            ..baseFat = food.fat
            ..kcal = food.kcal * ratio
            ..protein = food.protein * ratio
            ..carbs = food.carbs * ratio
            ..fat = food.fat * ratio);
        });
      }),
    );
  }

  void _editIngredient(int index, AppLocalizations l10n) {
    final item = _ingredients[index];
    double currentAmount = item.amount;
    final controller =
        TextEditingController(text: currentAmount.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (context) => StatefulBuilder(builder: (ctx, setModalState) {
        // CORREÇÃO: Definir colorScheme aqui para evitar erros
        final colorScheme = Theme.of(ctx).colorScheme;

        double ratio =
            (item.unit == 'un') ? currentAmount : (currentAmount / 100.0);

        double dKcal = item.baseKcal * ratio;
        double dProt = item.baseProtein * ratio;
        double dCarb = item.baseCarbs * ratio;
        double dFat = item.baseFat * ratio;

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
              top: 25,
              left: 25,
              right: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.batchCalcEditIngredient(item.foodName),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: controller, // CORREÇÃO: Usar o controller local
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: item.unit == 'un'
                      ? l10n.quantity("un")
                      : l10n.quantity("g"),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) {
                  setModalState(() {
                    currentAmount =
                        double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniMacroValue(dKcal, l10n.kcal, Colors.grey),
                    _miniMacroValue(
                        dProt, l10n.proteinShort, Colors.blueAccent),
                    _miniMacroValue(
                        dCarb, l10n.carbsShort, Colors.orangeAccent),
                    _miniMacroValue(dFat, l10n.fatShort, Colors.amber),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black),
                  onPressed: () {
                    setState(() {
                      item.amount = currentAmount;
                      double newRatio = (item.unit == 'un')
                          ? currentAmount
                          : (currentAmount / 100.0);
                      item.kcal = item.baseKcal * newRatio;
                      item.protein = item.baseProtein * newRatio;
                      item.carbs = item.baseCarbs * newRatio;
                      item.fat = item.baseFat * newRatio;
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.batchCalcAdjust.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  Widget _miniMacroValue(double val, String label, Color color) {
    String textVal = (label == "Kcal" || label == "Cal")
        ? val.toStringAsFixed(0)
        : val.toStringAsFixed(1);

    return Column(
      children: [
        Text(textVal,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))
      ],
    );
  }

  void _saveAsFood(AppLocalizations l10n) async {
    if (_ingredients.isEmpty) {
      AppToast.show(context, l10n.batchCalcNoIngredients, isError: true);
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.show(context, l10n.batchCalcNameRequired, isError: true);
      return;
    }

    if (_numMarmitas <= 0) {
      AppToast.show(context, l10n.batchCalcDosesError, isError: true);
      return;
    }

    final db = ref.read(databaseProvider);

    if (widget.existingMarmita == null) {
      final existing = await db.isar.foodItems
          .filter()
          .nameEqualTo(name, caseSensitive: false)
          .findFirst();

      if (existing != null) {
        if (!mounted) return;
        final bool? replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.duplicateFoodTitle),
            content: Text(l10n.duplicateFoodMessage(name)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.replace)),
            ],
          ),
        );
        if (replace == null || replace == false) return;
        widget.existingMarmita?.id = existing.id;
      }
    }

    final food = widget.existingMarmita ?? FoodItem();
    food.name = name;
    food.kcal = _totalKcal / _numMarmitas;
    food.protein = _totalProt / _numMarmitas;
    food.carbs = _totalCarb / _numMarmitas;
    food.fat = _totalFat / _numMarmitas;
    food.unit = 'un';
    food.source = l10n.sourceMarmita;
    food.isFavorite = true;
    food.portions = _numMarmitas;

    await db.isar.writeTxn(() async {
      final currentIds = _ingredients.map((e) => e.id).toSet();
      final idsToDelete = _originalIngredientIds
          .where((id) => !currentIds.contains(id))
          .toList();

      if (idsToDelete.isNotEmpty) {
        await db.isar.mealEntrys.deleteAll(idsToDelete);
      }
      await db.isar.mealEntrys.putAll(_ingredients);
      await db.isar.foodItems.put(food);
      food.ingredients.clear();
      food.ingredients.addAll(_ingredients);
      await food.ingredients.save();
    });
    CloudSyncService(db).syncFood(food);

    if (mounted) {
      AppToast.show(context, l10n.foodSaved);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final perMarmitaKcal = (_numMarmitas > 0) ? (_totalKcal / _numMarmitas) : 0;

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
                  color: const Color(0xFF00E676).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.soup_kitchen,
                    color: Color(0xFF00E676), size: 28),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.batchCalcTitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(
                      widget.existingMarmita != null
                          ? l10n.batchCalcAdjust
                          : l10n.batchCalcMarmita,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF00E676), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        // --- INPUT NOME (ESTILO ATUALIZADO) ---
                        TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: l10n.batchCalcNameHint,
                            hintStyle: TextStyle(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.normal,
                              fontSize: 22,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        // ----------------------------------------
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.batchCalcYield,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                initialValue: _numMarmitas.toStringAsFixed(0),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00E676)),
                                decoration: const InputDecoration(
                                    border: InputBorder.none, isDense: true),
                                onChanged: (v) {
                                  final val =
                                      double.tryParse(v.replaceAll(',', '.')) ??
                                          1;
                                  setState(() => _numMarmitas = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.batchCalcDoses,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 30),
                        Text(
                            "${perMarmitaKcal.toStringAsFixed(0)} ${l10n.kcal}",
                            style: const TextStyle(
                                fontSize: 40, fontWeight: FontWeight.bold)),
                        Text(l10n.batchCalcPerDose,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                letterSpacing: 2)),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _miniMacro((_totalProt / _numMarmitas),
                                l10n.proteinShort, Colors.blueAccent),
                            _miniMacro((_totalCarb / _numMarmitas),
                                l10n.carbsShort, Colors.orangeAccent),
                            _miniMacro((_totalFat / _numMarmitas),
                                l10n.fatShort, Colors.amber),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.batchCalcIngredients,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(l10n.batchCalcItems(_ingredients.length),
                          style: const TextStyle(color: Colors.grey))
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ingredients.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _ingredients[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _editIngredient(index, l10n),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.edit,
                              size: 16, color: Color(0xFF00E676)),
                        ),
                        title: Text(item.foodName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${item.amount.toStringAsFixed(1)}${item.unit}  •  ${item.kcal.toStringAsFixed(0)} ${l10n.kcal}"),
                            Text(
                              "${l10n.proteinShort.substring(0, 1)}: ${item.protein.toStringAsFixed(1)}  ${l10n.carbsShort.substring(0, 1)}: ${item.carbs.toStringAsFixed(1)}  ${l10n.fatShort.substring(0, 1)}: ${item.fat.toStringAsFixed(1)}",
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            )
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () =>
                              setState(() => _ingredients.removeAt(index)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                  top: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addIngredient,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(l10n.batchCalcAdd),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveAsFood(l10n),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                    ),
                    child: Text(l10n.batchCalcSaveAdjustments),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMacro(double val, String label, Color color) {
    if (val.isNaN || val.isInfinite) val = 0;
    return Column(children: [
      Text("${val.toStringAsFixed(1)}g",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey))
    ]);
  }
}

class _IngredientSearchModal extends ConsumerStatefulWidget {
  final Function(FoodItem, double) onSelect;
  const _IngredientSearchModal({required this.onSelect});
  @override
  ConsumerState<_IngredientSearchModal> createState() =>
      __IngredientSearchModalState();
}

class __IngredientSearchModalState
    extends ConsumerState<_IngredientSearchModal> {
  final _searchController = TextEditingController();
  List<FoodItem> _results = [];

  void _search(String query) async {
    if (query.isEmpty) return;
    final db = ref.read(databaseProvider);
    final words = normalizeForSearch(query)
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    var results = await db.isar.foodItems
        .filter()
        .allOf(words, (q, String w) => q.searchNameContains(w))
        .limit(20)
        .findAll();

    if (results.isEmpty && words.length > 1) {
      results = await db.isar.foodItems
          .filter()
          .anyOf(words, (q, String w) => q.searchNameContains(w))
          .limit(20)
          .findAll();
    }

    if (mounted) setState(() => _results = results);
  }

  void _openQuantitySheet(FoodItem food, AppLocalizations l10n) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (ctx) {
          double qtd = food.unit == 'un' ? 1.0 : 100.0;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
                top: 25,
                left: 25,
                right: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(food.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: food.unit == 'un'
                          ? l10n.quantity("un")
                          : l10n.quantity("g")),
                  onChanged: (v) =>
                      qtd = double.tryParse(v.replaceAll(',', '.')) ?? 0,
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    widget.onSelect(food, qtd);
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.confirm),
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
                labelText: l10n.batchCalcSearchIngredient,
                prefixIcon: const Icon(Icons.search)),
            onChanged: _search,
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final food = _results[index];
                return ListTile(
                  title: Text(food.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "${food.kcal.toStringAsFixed(0)} ${l10n.kcal} • ${l10n.proteinShort.substring(0, 1)}:${food.protein.toStringAsFixed(1)} ${l10n.carbsShort.substring(0, 1)}:${food.carbs.toStringAsFixed(1)} ${l10n.fatShort.substring(0, 1)}:${food.fat.toStringAsFixed(1)}"),
                  onTap: () => _openQuantitySheet(food, l10n),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
