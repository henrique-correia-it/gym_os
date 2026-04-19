import 'dart:async'; // Necessário para o Timer (Debounce)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:gym_os/l10n/app_localizations.dart'; // IMPORTANTE
import '../data/models/nutrition.dart';
import '../data/models/user.dart'; // <-- ADICIONADO PARA TER ACESSO AO USERSETTINGS
import '../providers/app_providers.dart';
import '../providers/daily_log_provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/food_api_service.dart';
import '../utils/text_normalize.dart';
import 'create_food_screen.dart';
import '../utils/app_toast.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  // Separamos as listas para evitar conflitos visuais
  List<FoodItem> _localResults = [];
  List<FoodItem> _apiResults = [];

  final _searchController = TextEditingController();
  final _apiService = FoodApiService();

  bool _isLoadingApi = false;
  Timer? _debounce; // Para aguardar que o utilizador pare de escrever
  String _currentQuery =
      ""; // Para validar se a resposta da API ainda é relevante

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Lógica de pesquisa robusta
  void _onSearchChanged(String query) {
    _currentQuery = query;

    // 1. Limpar listas se o texto estiver vazio
    if (query.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _localResults = [];
        _apiResults = [];
        _isLoadingApi = false;
      });
      return;
    }

    // 2. Pesquisa Local (Imediata - a BD local é super rápida e não custa dinheiro)
    _searchLocal(query);

    // 3. Pesquisa API (Debounced - Espera que o utilizador pare de escrever)
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Evita rajadas no endpoint de pesquisa do Open Food Facts.
    _debounce = Timer(const Duration(milliseconds: 1800), () {
      // Mantem a pesquisa local imediata e chama a API so para termos mais especificos.
      if (query.trim().length >= 4) {
        _searchApi(query);
      } else {
        setState(() {
          _apiResults = [];
          _isLoadingApi = false;
        });
      }
    });
  }

  Future<void> _searchLocal(String query) async {
    final db = ref.read(databaseProvider);
    final words = normalizeForSearch(query)
        .replaceAll('"', '')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      setState(() => _localResults = []);
      return;
    }

    // AND: todas as palavras presentes (mais preciso)
    var results = await db.isar.foodItems
        .filter()
        .allOf(words, (q, String w) => q.searchNameContains(w))
        .limit(20)
        .findAll();

    // OR fallback: se AND não devolver nada, aceita qualquer palavra
    if (results.isEmpty && words.length > 1) {
      results = await db.isar.foodItems
          .filter()
          .anyOf(words, (q, String w) => q.searchNameContains(w))
          .limit(20)
          .findAll();
    }

    if (_currentQuery == query && mounted) {
      setState(() => _localResults = results);
    }
  }

  Future<void> _searchApi(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoadingApi = true;
      _apiResults = []; // limpa resultados antigos imediatamente
    });

    try {
      // Tenta buscar à API
      final results = await _apiService.searchFood(query);

      // Verifica se a query ainda é a mesma
      if (_currentQuery != query) return;

      if (mounted) {
        setState(() {
          _apiResults = results;
          _isLoadingApi = false;
        });
      }
    } catch (e) {
      // ERRO CAPTURADO E TRATADO
      if (mounted && _currentQuery == query) {
        setState(() {
          _isLoadingApi = false;
          _apiResults = [];
        });

        if (_localResults.isNotEmpty) {
          return;
        }

        final l10n = AppLocalizations.of(context)!;
        final erroStr = e.toString();
        String mensagemErro = l10n.errorNetwork;

        if (erroStr.contains('rate_limit')) {
          mensagemErro = l10n.errorRateLimit;
        } else if (erroStr.contains('server_down')) {
          mensagemErro = l10n.errorServerDown;
        } else if (erroStr.contains('timeout_api')) {
          mensagemErro = l10n.errorServerSlow;
        }

        AppToast.show(context, mensagemErro, isError: true);
      }
    }
  }

  Future<void> _importAndEditFood(FoodItem apiItem) async {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);

    // 1. Criar cópia para a BD Local
    final newItem = FoodItem.fromApi(apiItem);

    // 2. Guardar na BD
    await db.isar.writeTxn(() async {
      await db.isar.foodItems.put(newItem);
    });
    CloudSyncService(db).syncFood(newItem);

    // 3. Atualizar pesquisa local
    _searchLocal(_searchController.text);

    // 4. Navegar para Edição
    if (!mounted) return;
    AppToast.show(context, l10n.imported); // TRADUZIDO

    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => CreateFoodScreen(foodToEdit: newItem)));

    // Atualizar após voltar da edição
    _onSearchChanged(_searchController.text);
  }

  // --- UI MODAL E WIDGETS ---
  void _showAddMealModal(FoodItem food) {
    final l10n = AppLocalizations.of(context)!;

    double amount = food.unit == 'un' ? 1.0 : 100.0;

    // ALTERAÇÃO 2: Variável nullable para não ter pré-seleção
    String? selectedMeal;
    bool showCheckError = false;

    final amountController =
        TextEditingController(text: amount.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double ratio = (food.unit == 'un') ? amount : (amount / 100.0);
            final totalKcal = food.kcal * ratio;
            final totalProt = food.protein * ratio;
            final totalCarb = food.carbs * ratio;
            final totalFat = food.fat * ratio;

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
                top: 12,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // — Drag handle —
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: food.source == 'API'
                                ? Colors.blueAccent.withOpacity(0.1)
                                : const Color(0xFF00E676).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            food.source == 'API'
                                ? Icons.cloud_download_rounded
                                : Icons.restaurant_menu_rounded,
                            color: food.source == 'API'
                                ? Colors.blueAccent
                                : const Color(0xFF00E676),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              _buildSourceBadge(context, food.source == 'API'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              // ALTERAÇÃO 1: autofocus false para o teclado não abrir sozinho
                              autofocus: false,
                              style: const TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: l10n.quantity(food.unit == 'un'
                                    ? l10n.unitUn
                                    : l10n.unitG),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                labelStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                              onChanged: (value) {
                                final val = double.tryParse(
                                        value.replaceAll(',', '.')) ??
                                    0;
                                setModalState(() => amount = val);
                              },
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.withAlpha(30)),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                totalKcal.toStringAsFixed(0),
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00E676)),
                              ),
                              Text(l10n.unitKcal,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildMacroBadge(context, l10n.protein, totalProt,
                            Colors.blueAccent),
                        const SizedBox(width: 10),
                        _buildMacroBadge(context, l10n.carbs, totalCarb,
                            Colors.orangeAccent),
                        const SizedBox(width: 10),
                        _buildMacroBadge(
                            context, l10n.fat, totalFat, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // — Section label —
                    Row(
                      children: [
                        Icon(Icons.restaurant_rounded,
                            size: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          l10n.chooseMealType,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            ref.read(mealOrderProvider).map((mealKey) {
                          final isSelected = selectedMeal == mealKey;
                          final displayLabel =
                              _getTranslatedMealName(context, mealKey);
                          return GestureDetector(
                            onTap: () => setModalState(() {
                              selectedMeal = isSelected ? null : mealKey;
                              if (!isSelected) showCheckError = false;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00E676)
                                        .withValues(alpha: 0.12)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00E676)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                displayLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? const Color(0xFF00E676)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (showCheckError) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l10n.selectMealError,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E676), Color(0xFF00C853)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () {
                            if (selectedMeal == null) {
                              setModalState(() => showCheckError = true);
                              return;
                            }
                            ref
                                .read(dailyLogProvider.notifier)
                                .addMeal(food, amount, selectedMeal!);
                            Navigator.pop(context);
                            AppToast.show(
                                context, l10n.foodAdded(food.name));
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.addToDiary,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPER DE TRADUÇÃO DE REFEIÇÕES ---
  String _getTranslatedMealName(BuildContext context, String rawKey) {
    final l10n = AppLocalizations.of(context)!;
    final key = rawKey.trim().toLowerCase();

    if (key.contains('pequeno') ||
        key.contains('breakfast') ||
        key.contains('desayuno') ||
        key.contains('peq')) {
      return l10n.mealBreakfast;
    }
    if (key == 'almoço' ||
        key == 'almoco' ||
        key == 'lunch' ||
        key == 'almuerzo') {
      return l10n.mealLunch;
    }
    if (key == 'lanche' || key == 'snack' || key == 'merienda') {
      return l10n.mealSnack;
    }
    if (key == 'jantar' || key == 'dinner' || key == 'cena') {
      return l10n.mealDinner;
    }
    if (key == 'ceia' || key == 'supper' || key == 'recena') {
      return l10n.mealSupper;
    }
    if (key.contains('pré') || key.contains('pre-')) {
      return l10n.mealPreWorkout;
    }
    if (key.contains('pós') || key.contains('post') || key.contains('pos-')) {
      return l10n.mealPostWorkout;
    }
    if (key == 'outros' || key == 'others' || key == 'otros') {
      return l10n.mealOthers;
    }

    return rawKey;
  }

  Widget _buildMacroBadge(
      BuildContext context, String label, double value, Color color) {
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17, color: color),
            ),
            const SizedBox(height: 2),
            Text(l10n.unitG,
                style: TextStyle(
                    fontSize: 10, color: color.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context, bool isApi) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isApi
            ? Colors.blueAccent.withAlpha(10)
            : const Color(0xFF00E676).withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isApi
                ? Colors.blueAccent.withAlpha(30)
                : const Color(0xFF00E676).withAlpha(30),
            width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isApi ? Icons.public : Icons.folder_special,
              size: 10,
              color: isApi ? Colors.blueAccent : const Color(0xFF00E676)),
          const SizedBox(width: 4),
          Text(
            isApi ? l10n.onlineLabel : l10n.myFoodsLabel,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isApi ? Colors.blueAccent : const Color(0xFF00E676)),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMacro(String label, double val, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 3),
        Text("${val.toStringAsFixed(0)}$label",
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withOpacity(0.8))),
      ],
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(selectedDateProvider);
    final dailyLog = ref.watch(dailyLogProvider).valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;

    final combinedResults = [..._localResults, ..._apiResults];

    final consumed = dailyLog?.consumedKcal ?? 0;
    final target = dailyLog?.targetKcal ?? 0;
    final kcalSubtitle = dailyLog != null
        ? '${consumed.toInt()} / ${target.toInt()} kcal'
        : null;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: Color(0xFF00E676), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.navDiet,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    )),
                if (kcalSubtitle != null)
                  Text(kcalSubtitle,
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
      body: Column(
        children: [
          // --- BARRA DE PESQUISA + BOTÃO CRIAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                // Barra de Pesquisa
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: l10n.searchPlaceholder,
                        hintStyle:
                            TextStyle(color: Colors.grey.withOpacity(0.7)),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _isLoadingApi
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5))
                              : const Icon(Icons.search_rounded,
                                  color: Color(0xFF00E676), size: 26),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Botão [+] Elegante
                Container(
                  height: 54, // Altura ajustada para alinhar com a barra
                  width: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => CreateFoodScreen(
                              // Passa logo o que o utilizador já escreveu!
                              initialName: _searchController.text,
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- LISTA DE RESULTADOS ---
          Expanded(
            child: combinedResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_search_rounded,
                            size: 80,
                            color: Theme.of(context)
                                .dividerColor
                                .withOpacity(0.15)),
                        const SizedBox(height: 15),
                        Text(l10n.searchEmptyTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.withOpacity(0.6),
                                fontSize: 16)),
                        const SizedBox(height: 20),
                        if (_searchController.text.isNotEmpty && !_isLoadingApi)
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => CreateFoodScreen(
                                        initialName: _searchController.text))),
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00E676),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                backgroundColor:
                                    const Color(0xFF00E676).withOpacity(0.05)),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label:
                                Text(l10n.createFood(_searchController.text)),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: combinedResults.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final food = combinedResults[index];
                      final isApi = food.source == 'API';

                      final tileWidget = Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showAddMealModal(food),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Ícone
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: isApi
                                          ? Colors.blueAccent.withOpacity(0.1)
                                          : const Color(0xFF00E676)
                                              .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isApi
                                          ? Icons.cloud
                                          : Icons.local_dining_rounded,
                                      color: isApi
                                          ? Colors.blueAccent
                                          : const Color(0xFF00E676),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Texto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                food.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Infos de Macros na lista
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${food.kcal.toStringAsFixed(0)} ${l10n.unitKcal} • ${food.unit == 'un' ? '1 ${l10n.unitUn}' : l10n.unit100g}",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: Colors.grey
                                                        .withOpacity(0.9)),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildMicroMacro(
                                                l10n.proteinShort,
                                                food.protein,
                                                Colors.blueAccent),
                                            const SizedBox(width: 8),
                                            _buildMicroMacro(
                                                l10n.carbsShort,
                                                food.carbs,
                                                Colors.orangeAccent),
                                            const SizedBox(width: 8),
                                            _buildMicroMacro(l10n.fatShort,
                                                food.fat, Colors.redAccent),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.add_circle_rounded,
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.3),
                                      size: 28)
                                ],
                              ),
                            ),
                          ),
                        ),
                      );

                      // LÓGICA DE ARRASTAR (SWIPE)
                      return Dismissible(
                        key: Key(food.id.toString()),
                        direction: isApi
                            ? DismissDirection.startToEnd
                            : DismissDirection.horizontal,

                        // Swipe para DIREITA (EDITAR)
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 10),
                              Text(isApi ? l10n.importAndEdit : l10n.editAction,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))
                            ],
                          ),
                        ),

                        // Swipe para ESQUERDA (APAGAR - Apenas DB)
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white),
                        ),

                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            if (isApi) {
                              await _importAndEditFood(food);
                            } else {
                              final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) =>
                                          CreateFoodScreen(foodToEdit: food)));
                              if (result == true) {
                                _onSearchChanged(_searchController.text);
                              }
                            }
                            return false;
                          } else {
                            // --- LÓGICA DE APAGAR CORRIGIDA AQUI ---
                            final db = ref.read(databaseProvider);
                            final cloudSync = CloudSyncService(db);
                            final isar = db.isar;

                            if (food.source == 'Geral') {
                              // 1. É DO JSON: Ocultamos apenas para este utilizador
                              await isar.writeTxn(() async {
                                final userSettings =
                                    await isar.userSettings.where().findFirst();
                                if (userSettings != null) {
                                  // Adiciona o NOME do alimento à lista negra
                                  userSettings.hiddenGlobalFoods = [
                                    ...userSettings.hiddenGlobalFoods,
                                    food.name
                                  ];
                                  await isar.userSettings.put(userSettings);
                                }
                                // Apaga localmente
                                await isar.foodItems.delete(food.id);
                              });
                              // Sincroniza APENAS as definições do utilizador (muito leve!)
                              await cloudSync.syncUserSettings();
                            } else {
                              // 2. É DO UTILIZADOR/API: Apaga de vez de todo o lado
                              await isar.writeTxn(() async {
                                await isar.foodItems.delete(food.id);
                              });
                              // Apaga da nuvem
                              await cloudSync.deleteFood(food.id);
                            }

                            if (context.mounted) {
                              AppToast.show(
                                  context, l10n.foodDeleted(food.name));
                            }

                            setState(() {
                              // Usar removeWhere é mais seguro do que removeAt para garantir que
                              // removemos o alimento certo independentemente dos items da API.
                              _localResults
                                  .removeWhere((item) => item.id == food.id);
                            });

                            return true;
                          }
                        },
                        child: tileWidget,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
