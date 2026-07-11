import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/nutrition.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_toast.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

class CerealCalculatorScreen extends ConsumerStatefulWidget {
  const CerealCalculatorScreen({super.key});

  @override
  ConsumerState<CerealCalculatorScreen> createState() =>
      _CerealCalculatorScreenState();
}

class _CerealCalculatorScreenState
    extends ConsumerState<CerealCalculatorScreen> {
  // --- Inputs Principais ---
  final _targetKcalController = TextEditingController(text: "500");
  final _targetVolumeController = TextEditingController(text: "250");

  bool _isVolumeMode = false;

  FoodItem? _powderItem;
  FoodItem? _liquidItem;

  String _mealType = "";

  // --- Constantes de Textura ---
  final double _stdSolid = 30.0;
  final double _stdLiquid = 160.0;

  // --- Resultados Calculados ---
  double _resCerealGrams = 0;
  double _resMilkMl = 0;
  double _resWaterMl = 0;
  double _resTotalKcal = 0;

  @override
  void initState() {
    super.initState();
    // No initState() já não chamamos o AppLocalizations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculate();
    });
  }

  // CORREÇÃO AQUI: Usamos o didChangeDependencies para aceder ao context de forma segura
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Garantimos que só inicializa o fallback se ainda estiver vazio
    if (_mealType.isEmpty) {
      final order = ref.read(mealOrderProvider);
      _mealType = order.isNotEmpty
          ? order.first
          : AppLocalizations.of(context)!.mealBreakfast;
    }
  }

  // ===========================================================================
  // CÁLCULOS
  // ===========================================================================
  void _calculate() {
    final targetKcal =
        double.tryParse(_targetKcalController.text.replaceAll(',', '.')) ?? 0;
    final targetVol =
        double.tryParse(_targetVolumeController.text.replaceAll(',', '.')) ?? 0;

    if (_powderItem == null || targetKcal <= 0) {
      _resetResults();
      return;
    }

    double cerealKcalPerG = _powderItem!.kcal / 100.0;
    double liquidKcalPerMl = (_liquidItem?.kcal ?? 0) / 100.0;
    double textureRatio = _stdLiquid / _stdSolid;
    bool isWater = _liquidItem == null || _liquidItem!.kcal < 1;

    if (isWater) {
      _resCerealGrams = targetKcal / cerealKcalPerG;
      _resMilkMl = 0;
      _resWaterMl = _resCerealGrams * textureRatio;
    } else if (_isVolumeMode) {
      _resCerealGrams = (targetVol * _stdSolid) / _stdLiquid;
      double currentKcal = _resCerealGrams * cerealKcalPerG;
      double remainingKcal = targetKcal - currentKcal;

      if (remainingKcal <= 0) {
        _resMilkMl = 0;
        _resWaterMl = targetVol;
      } else {
        if (liquidKcalPerMl > 0) {
          _resMilkMl = remainingKcal / liquidKcalPerMl;
        } else {
          _resMilkMl = 0;
        }
        _resWaterMl = targetVol - _resMilkMl;
        if (_resWaterMl < 0) _resWaterMl = 0;
      }
    } else {
      double denominator = cerealKcalPerG + (textureRatio * liquidKcalPerMl);
      if (denominator == 0) {
        _resetResults();
        return;
      }
      _resCerealGrams = targetKcal / denominator;
      _resMilkMl = _resCerealGrams * textureRatio;
      _resWaterMl = 0;
    }

    double finalCerealKcal = (_resCerealGrams * cerealKcalPerG);
    double finalMilkKcal = (_resMilkMl * liquidKcalPerMl);

    setState(() {
      _resTotalKcal = finalCerealKcal + finalMilkKcal;
    });
  }

  void _resetResults() {
    setState(() {
      _resCerealGrams = 0;
      _resMilkMl = 0;
      _resWaterMl = 0;
      _resTotalKcal = 0;
    });
  }

  // ===========================================================================
  // MODAL DE CONFIRMAÇÃO
  // ===========================================================================
  void _showConfirmationModal(AppLocalizations l10n) {
    if (_powderItem == null || _resCerealGrams <= 0) {
      AppToast.show(context, l10n.cerealCalcConfigureFirst);
      return;
    }

    final mealOrderNow = ref.read(mealOrderProvider);
    if (!mealOrderNow.contains(_mealType)) {
      if (mealOrderNow.isNotEmpty) _mealType = mealOrderNow.first;
    }

    String modalName = l10n.porridgeOf(_powderItem!.name);
    if (_liquidItem != null && _resMilkMl > 10) {
      modalName += " + ${_liquidItem!.name}";
    }
    String modalMealType = _mealType;

    // Controladores de QUANTIDADE (Editáveis)
    final cerealWeightCtrl =
        TextEditingController(text: _resCerealGrams.toStringAsFixed(0));
    final liquidWeightCtrl =
        TextEditingController(text: _resMilkMl.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          double cWeight =
              double.tryParse(cerealWeightCtrl.text.replaceAll(',', '.')) ?? 0;
          double lWeight =
              double.tryParse(liquidWeightCtrl.text.replaceAll(',', '.')) ?? 0;

          // Recalcular Macros Totais
          double cKcal = (cWeight * _powderItem!.kcal) / 100;
          double cProt = (cWeight * _powderItem!.protein) / 100;
          double cCarb = (cWeight * _powderItem!.carbs) / 100;
          double cFat = (cWeight * _powderItem!.fat) / 100;

          double lKcal = 0, lProt = 0, lCarb = 0, lFat = 0;
          if (_liquidItem != null) {
            lKcal = (lWeight * _liquidItem!.kcal) / 100;
            lProt = (lWeight * _liquidItem!.protein) / 100;
            lCarb = (lWeight * _liquidItem!.carbs) / 100;
            lFat = (lWeight * _liquidItem!.fat) / 100;
          }

          double finalKcal = cKcal + lKcal;
          double finalProt = cProt + lProt;
          double finalCarb = cCarb + lCarb;
          double finalFat = cFat + lFat;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 25,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.finalAdjustment,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // NOME E TIPO
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: l10n.foodName,
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        controller: TextEditingController(text: modalName),
                        onChanged: (v) => modalName = v,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.meals,
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: modalMealType,
                            isExpanded: true,
                            items: ref.watch(mealOrderProvider).map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                    TranslationHelper.translateMeal(
                                        context, value), // <--- CORRIGIDO
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => modalMealType = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // INGREDIENTES EDITÁVEIS
                // --- CORREÇÃO 1: Usar l10n e remover const ---
                Text(l10n.cerealCalcEditIngredients,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _buildEditableIngredient(
                            label: "${l10n.cerealCalcCereal} (g)",
                            ctrl: cerealWeightCtrl,
                            color: Colors.amber,
                            onChange: (_) => setModalState(() {}))),
                    const SizedBox(width: 10),
                    if (_liquidItem != null)
                      Expanded(
                          child: _buildEditableIngredient(
                              label: "${l10n.cerealCalcLiquid} (ml)",
                              ctrl: liquidWeightCtrl,
                              color: Colors.blue,
                              onChange: (_) => setModalState(() {}))),
                  ],
                ),

                const SizedBox(height: 20),

                // MACROS CALCULADOS (READ ONLY)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildReadOnlyMacro(
                          l10n.kcal,
                          finalKcal.toStringAsFixed(0),
                          const Color(0xFF00E676)),
                      // --- CORREÇÃO 2: Usar chaves Short para evitar crash em inglês ---
                      _buildReadOnlyMacro(
                          l10n.proteinShort, // "Prot"
                          finalKcal > 0
                              ? "${finalProt.toStringAsFixed(1)}g"
                              : "-",
                          Colors.blue),
                      _buildReadOnlyMacro(
                          l10n.carbsShort, // "Carb" / "Hidr"
                          finalKcal > 0
                              ? "${finalCarb.toStringAsFixed(1)}g"
                              : "-",
                          Colors.orange),
                      _buildReadOnlyMacro(
                          l10n.fatShort, // "Fat" / "Gord"
                          finalKcal > 0
                              ? "${finalFat.toStringAsFixed(1)}g"
                              : "-",
                          Colors.red),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // BOTÃO SALVAR
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        final db = ref.read(databaseProvider);

                        final now = DateTime.now();
                        final todayDate =
                            DateTime(now.year, now.month, now.day);

                        final newMeal = MealEntry()
                          ..foodName = modalName
                          ..type = modalMealType
                          ..amount = 1.0
                          ..unit = "un"
                          ..kcal = finalKcal
                          ..protein = finalProt
                          ..carbs = finalCarb
                          ..fat = finalFat
                          ..baseKcal = finalKcal
                          ..baseProtein = finalProt
                          ..baseCarbs = finalCarb
                          ..baseFat = finalFat;

                        await db.isar.writeTxn(() async {
                          await db.isar.mealEntrys.put(newMeal);

                          var dayLog = await db.isar.dayLogs
                              .filter()
                              .dateEqualTo(todayDate)
                              .findFirst();

                          if (dayLog == null) {
                            dayLog = DayLog()..date = todayDate;
                            await db.isar.dayLogs.put(dayLog);
                          }

                          dayLog.meals.add(newMeal);
                          await dayLog.meals.save();
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          AppToast.show(context, l10n.cerealCalcAdded);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.show(context, "${l10n.error}: $e");
                        }
                      }
                    },
                    child: Text(l10n.cerealCalcAddAsDose,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildEditableIngredient(
      {required String label,
      required TextEditingController ctrl,
      required Color color,
      required Function(String) onChange}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChange,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }

  Widget _buildReadOnlyMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // ===========================================================================
  // UI PRINCIPAL
  // ===========================================================================

  void _openFoodSelector(bool isLiquid, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocalFoodSearchModal(
        title: isLiquid
            ? l10n.cerealCalcChooseLiquid
            : l10n.cerealCalcChooseCereal,
        filterLiquids: isLiquid,
        onFoodSelected: (food) {
          setState(() {
            if (isLiquid) {
              _liquidItem = food;
            } else {
              _powderItem = food;
            }
          });
          _calculate();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade800.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.breakfast_dining_rounded,
                  color: Colors.amber.shade800, size: 28),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.utilities,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w500,
                    )),
                Text(l10n.toolsCereal,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    )),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- META ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00C853)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Text(l10n.cerealCalcCalorieGoal,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _targetKcalController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      suffixText: "kcal",
                      suffixStyle:
                          TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- INGREDIENTES ---
            Row(
              children: [
                Expanded(
                  child: _buildSelector(
                    title: l10n.cerealCalcCereal,
                    item: _powderItem,
                    icon: Icons.grain,
                    color: Colors.amber,
                    onTap: () => _openFoodSelector(false, l10n),
                    placeholder: l10n.cerealCalcSelect,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildSelector(
                    title: l10n.cerealCalcLiquid,
                    item: _liquidItem,
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    onTap: () => _openFoodSelector(true, l10n),
                    placeholder: l10n.cerealCalcWater,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- OPÇÕES ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(l10n.cerealCalcAdjustVolume,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(l10n.cerealCalcAdjustVolumeSub,
                        style: const TextStyle(fontSize: 12)),
                    value: _isVolumeMode,
                    activeTrackColor: const Color(0xFF00E676),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _isVolumeMode = val);
                      _calculate();
                    },
                  ),
                  if (_isVolumeMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: _targetVolumeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "${l10n.cerealCalcTotalVolume} (ml)",
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          suffixText: "ml",
                        ),
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- RESULTADOS ---
            if (_powderItem != null)
              Column(
                children: [
                  Text(l10n.cerealCalcCalculatedRecipe,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                          color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildResultCard(
                          l10n.cerealCalcCereal,
                          "${_resCerealGrams.toStringAsFixed(0)}g",
                          Colors.amber),
                      const Icon(Icons.add, color: Colors.grey),
                      _buildResultCard(l10n.cerealCalcLiquid,
                          "${_resMilkMl.toStringAsFixed(0)}ml", Colors.blue),
                      const Icon(Icons.add, color: Colors.grey),
                      _buildResultCard(l10n.cerealCalcWater,
                          "${_resWaterMl.toStringAsFixed(0)}ml", Colors.cyan),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.cerealCalcEstimate(_resTotalKcal.toStringAsFixed(0)),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _resTotalKcal >
                                (double.tryParse(_targetKcalController.text
                                            .replaceAll(',', '.')) ??
                                        0) +
                                    10
                            ? Colors.red
                            : Colors.green),
                  )
                ],
              ),

            const SizedBox(height: 40),

            // --- BOTÃO ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _showConfirmationModal(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(l10n.addToDiary,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelector(
      {required String title,
      required FoodItem? item,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      required String placeholder}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: item != null ? color : Colors.grey.withValues(alpha: 0.2),
              width: item != null ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item?.name ?? placeholder,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: item != null ? null : Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// =============================================================================
// MODAL DE PESQUISA (Local)
// =============================================================================
class _LocalFoodSearchModal extends ConsumerStatefulWidget {
  final String title;
  final bool filterLiquids;
  final Function(FoodItem) onFoodSelected;

  const _LocalFoodSearchModal(
      {required this.title,
      required this.filterLiquids,
      required this.onFoodSelected});

  @override
  ConsumerState<_LocalFoodSearchModal> createState() =>
      _LocalFoodSearchModalState();
}

class _LocalFoodSearchModalState extends ConsumerState<_LocalFoodSearchModal> {
  final _searchController = TextEditingController();
  List<FoodItem> _results = [];

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    final db = ref.read(databaseProvider);

    List<FoodItem> items;

    if (widget.filterLiquids) {
      items = await db.isar.foodItems
          .filter()
          .group((g) => g
              .nameContains("leite", caseSensitive: false)
              .or()
              .nameContains("iogurte", caseSensitive: false)
              .or()
              .nameContains("bebida", caseSensitive: false)
              .or()
              .nameContains("agua", caseSensitive: false)
              .or()
              .nameContains("water", caseSensitive: false)
              .or()
              .nameContains("batido", caseSensitive: false)
              .or()
              .nameContains("milk", caseSensitive: false))
          .limit(20)
          .findAll();
    } else {
      items = await db.isar.foodItems
          .filter()
          .group((g) => g
              .nameContains("nestum", caseSensitive: false)
              .or()
              .nameContains("cerelac", caseSensitive: false)
              .or()
              .nameContains("farinha", caseSensitive: false)
              .or()
              .nameContains("aveia", caseSensitive: false)
              .or()
              .nameContains("papa", caseSensitive: false)
              .or()
              .nameContains("arroz", caseSensitive: false))
          .limit(20)
          .findAll();
    }

    if (mounted) setState(() => _results = items);
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _initialLoad();
      return;
    }
    final db = ref.read(databaseProvider);

    final items = await db.isar.foodItems
        .filter()
        .nameContains(query, caseSensitive: false)
        .limit(20)
        .findAll();

    if (mounted) setState(() => _results = items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(children: [
        const SizedBox(height: 15),
        Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
                hintText: l10n.searchWord,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search)),
            onChanged: _search,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Text(_results[i].name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "${_results[i].kcal.toInt()} kcal / 100${_results[i].unit}"),
              onTap: () => widget.onFoodSelected(_results[i]),
            ),
          ),
        )
      ]),
    );
  }
}
