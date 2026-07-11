import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/data/models/nutrition.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import '../data/models/user.dart';
import '../providers/app_providers.dart';
import '../services/cloud_sync_service.dart';
import '../utils/app_toast.dart';

class MacroSettingsScreen extends ConsumerStatefulWidget {
  const MacroSettingsScreen({super.key});

  @override
  ConsumerState<MacroSettingsScreen> createState() =>
      _MacroSettingsScreenState();
}

class _MacroSettingsScreenState extends ConsumerState<MacroSettingsScreen> {
  double _protein = 30, _carbs = 40, _fat = 30;
  bool _isLoading = true;

  // Variável para armazenar as calorias diárias alvo do utilizador e calcular as gramas
  double _targetKcal = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Função auxiliar para calcular a idade
  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Calcula a estimativa de calorias diárias (TDEE + Ajuste) para a conversão em gramas
  double _calculateTargetKcal(UserSettings user) {
    double weight = user.weight;
    double height = user.height;
    int age = _calculateAge(user.birthDate);

    if (weight > 0 && height > 0 && age > 0) {
      double bmr;
      if (user.gender == 'M') {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }
      double tdee = bmr * user.activityLevel;
      return tdee + user.caloricAdjustment;
    }
    return 2000.0; // Valor de fallback (padrão) se o utilizador não tiver perfil preenchido
  }

  Future<void> _loadSettings() async {
    final db = ref.read(databaseProvider);
    final user = await db.isar.userSettings.where().findFirst();
    if (user != null) {
      setState(() {
        _protein = user.macroProtein * 100;
        _carbs = user.macroCarbs * 100;
        _fat = user.macroFat * 100;
        _targetKcal = _calculateTargetKcal(user);
        _isLoading = false;
      });
    } else {
      setState(() {
        _targetKcal = 2000.0; // Fallback
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final db = ref.read(databaseProvider);

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // 1. Criar uma lista para memorizar quais os dias que alterámos
    List<DayLog> logsToSync = [];

    await db.isar.writeTxn(() async {
      // Atualizar o Perfil Global
      final user = await db.isar.userSettings.where().findFirst();
      if (user != null) {
        user.macroProtein = _protein / 100.0;
        user.macroCarbs = _carbs / 100.0;
        user.macroFat = _fat / 100.0;
        await db.isar.userSettings.put(user);
      }

      // Atualizar os dias de Hoje e do Futuro
      final futureLogs = await db.isar.dayLogs
          .filter()
          .dateGreaterThan(startOfToday, include: true)
          .findAll();

      for (var log in futureLogs) {
        double kcal = log.targetKcal > 0 ? log.targetKcal : 2000;
        log.targetProtein = (kcal * (_protein / 100.0)) / 4.0;
        log.targetCarbs = (kcal * (_carbs / 100.0)) / 4.0;
        log.targetFat = (kcal * (_fat / 100.0)) / 9.0;
        await db.isar.dayLogs.put(log);

        // Guarda o dia modificado na lista
        logsToSync.add(log);
      }
    });

    // 2. ENVIAR TUDO PARA O FIREBASE (Fora da transação)
    final syncService = CloudSyncService(db);

    // Envia o perfil atualizado
    syncService.syncUserSettings(force: true);

    // Envia cada dia que sofreu alterações para a nuvem
    for (var log in logsToSync) {
      syncService.syncDayLog(log);
    }

    if (mounted) {
      AppToast.show(context, l10n.goalsUpdated);
      Navigator.pop(context);
    }
  }

  // --- SMART FEATURE: Aplica presets automáticos ---
  void _applyPreset(double p, double c, double f) {
    setState(() {
      _protein = p;
      _carbs = c;
      _fat = f;
    });
    // Feedback tátil subtil
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double total = _protein + _carbs + _fat;
    bool isValid = (total - 100).abs() < 0.1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Cálculos dinâmicos de gramas com base nas calorias e percentagens
    // Proteína e Hidratos têm 4 kcal por grama; Gordura tem 9 kcal por grama.
    int proteinGrams =
        (_targetKcal > 0) ? ((_targetKcal * (_protein / 100)) / 4).round() : 0;
    int carbsGrams =
        (_targetKcal > 0) ? ((_targetKcal * (_carbs / 100)) / 4).round() : 0;
    int fatGrams =
        (_targetKcal > 0) ? ((_targetKcal * (_fat / 100)) / 9).round() : 0;

    return Scaffold(
      appBar: _buildPremiumAppBar(l10n),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 10, 20, MediaQuery.of(context).padding.bottom + 40),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeroCard(l10n, total, isValid, isDark),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.macroSmartPresetsTitle),
          _buildSmartPresetsRow(isDark, l10n),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.macroDistributionSection),
          _buildFormGroup(
            isDark: isDark,
            children: [
              _buildMacroSlider(
                label: l10n.protein,
                value: _protein,
                grams: proteinGrams,
                color: const Color(0xFF29B6F6), // Azul
                icon: Icons.fitness_center,
                onChanged: (v) => setState(() => _protein = v),
              ),
              _buildDivider(isDark),
              _buildMacroSlider(
                label: l10n.carbs,
                value: _carbs,
                grams: carbsGrams,
                color: const Color(0xFFFFA726), // Laranja
                icon: Icons.bolt,
                onChanged: (v) => setState(() => _carbs = v),
              ),
              _buildDivider(isDark),
              _buildMacroSlider(
                label: l10n.fat,
                value: _fat,
                grams: fatGrams,
                color: const Color(0xFFEF5350), // Vermelho
                icon: Icons.opacity,
                onChanged: (v) => setState(() => _fat = v),
              ),
            ],
          ),
          if (_targetKcal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 12, right: 12),
              child: Text(
                l10n.macroCalculationBase(_targetKcal.toStringAsFixed(0)),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 32),
          _buildCleanSaveButton(l10n, isValid),
        ],
      ),
    );
  }

  // =========================================================================
  // UI COMPONENTS - PREMIUM REDESIGN
  // =========================================================================

  PreferredSizeWidget _buildPremiumAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        l10n.macroDistribution,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      AppLocalizations l10n, double total, bool isValid, bool isDark) {
    final statusColor =
        isValid ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    String statusMessage = "";
    if (isValid) {
      statusMessage = l10n.macroStatusPerfect;
    } else if (total > 100) {
      statusMessage = l10n.macroStatusExcess((total - 100).toStringAsFixed(0));
    } else {
      statusMessage = l10n.macroStatusMissing((100 - total).toStringAsFixed(0));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
              : [Colors.white, const Color(0xFFF5F7FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(100)
                : Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: statusColor.withAlpha(isValid ? 15 : 25),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(
          color: statusColor.withAlpha(isValid ? 40 : 80),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusMessage,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                total.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -2,
                  color: isValid
                      ? Theme.of(context).colorScheme.onSurface
                      : statusColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "%",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isValid
                      ? Theme.of(context).colorScheme.onSurface.withAlpha(150)
                      : statusColor.withAlpha(200),
                ),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 12),
            Text(
              l10n.mustBe100,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
        ),
      ),
    );
  }

  // --- WIDGET DOS SMART PRESETS ---
  Widget _buildSmartPresetsRow(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildPresetChip(l10n.macroPresetBalanced, 30, 40, 30, isDark),
          _buildPresetChip(l10n.macroPresetHypertrophy, 35, 45, 20, isDark),
          _buildPresetChip(l10n.macroPresetLowCarb, 40, 20, 40, isDark),
        ],
      ),
    );
  }

  Widget _buildPresetChip(
      String label, double p, double c, double f, bool isDark) {
    // Verifica se este preset é o que está atualmente selecionado
    bool isSelected = (_protein == p && _carbs == c && _fat == f);

    return InkWell(
      onTap: () => _applyPreset(p, c, f),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E676).withAlpha(20)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E676)
                : (isDark
                    ? Colors.white.withAlpha(10)
                    : Colors.black.withAlpha(10)),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Adicionado para não expandir
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? const Color(0xFF00E676)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${p.toInt()}/${c.toInt()}/${f.toInt()}",
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormGroup(
      {required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
      ),
    );
  }

  Widget _buildIconCircle(IconData icon, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildMacroSlider({
    required String label,
    required double value,
    required int grams,
    required Color color,
    required IconData icon,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconCircle(icon, color: color),
              const SizedBox(width: 16),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Badge de Gramas dinâmico
              if (grams > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${grams}g",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(150),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                "${value.toInt()}%",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withAlpha(20),
              thumbColor: color,
              overlayColor: color.withAlpha(30),
              trackHeight: 6.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanSaveButton(AppLocalizations l10n, bool isValid) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          disabledBackgroundColor:
              Theme.of(context).colorScheme.onSurface.withAlpha(20),
          disabledForegroundColor:
              Theme.of(context).colorScheme.onSurface.withAlpha(100),
          foregroundColor: Colors.black,
          elevation: isValid ? 6 : 0,
          shadowColor: const Color(0xFF00E676).withAlpha(100),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: isValid ? _save : null,
        child: Text(
          l10n.saveSettings.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
