import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../data/models/user.dart';
import '../data/models/nutrition.dart';
import '../providers/app_providers.dart';
import '../providers/daily_log_provider.dart';
import '../services/cloud_sync_service.dart';
import '../utils/app_toast.dart';
import 'settings_screen.dart';
import 'macro_settings_screen.dart';
import 'tools/weight_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _adjustmentController = TextEditingController();

  String _currentWeightDisplay = "";
  DateTime? _selectedDate;
  double _activityLevel = 1.2;
  String _gender = 'M';
  bool _isLoading = true;

  double _bmr = 0;
  double _tdee = 0;
  double _finalTarget = 0;
  int _calculatedAge = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _adjustmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final db = ref.read(databaseProvider);
    final user = await db.isar.userSettings.where().findFirst();

    final latestEntry = await db.isar.weightEntrys
        .where()
        .anyDate()
        .sortByDateDesc()
        .findFirst();

    // Prefer the most recent weight entry; fall back to user.weight only if it
    // was explicitly set (i.e. saved at least once through the profile form).
    double displayWeight = latestEntry?.weight ?? 0.0;
    if (displayWeight <= 0 && user != null && user.weight > 0) {
      displayWeight = user.weight;
    }

    String initialName = user?.name ?? "";
    if (mounted) {
      if (initialName == "Utilizador" ||
          initialName == "Usuario" ||
          initialName == "User") {
        initialName = AppLocalizations.of(context)!.defaultUserName;
      } else if (initialName == "Atleta" || initialName == "Athlete") {
        initialName = AppLocalizations.of(context)!.defaultUserNameAthlete;
      }
    }

    _nameController.text = initialName;
    _currentWeightDisplay =
        displayWeight > 0 ? displayWeight.toStringAsFixed(2) : "";
    _heightController.text =
        (user != null && user.height > 0) ? user.height.toString() : "";
    _adjustmentController.text =
        (user?.caloricAdjustment ?? 0).toInt().toString();

    _selectedDate = user?.birthDate;

    if (user != null) {
      _activityLevel = user.activityLevel;
      _gender = user.gender;
    }

    _recalculateStats();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _goToWeightHistory() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (c) => const WeightHistoryScreen()));

    final db = ref.read(databaseProvider);
    final latestEntry =
        await db.isar.weightEntrys.where().sortByDateDesc().findFirst();

    if (latestEntry != null && mounted) {
      setState(() {
        _currentWeightDisplay = latestEntry.weight.toStringAsFixed(2);
        _recalculateStats();
      });
    }
  }

  double _safeParseDouble(String text) {
    if (text.isEmpty || text == "-" || text == ".") return 0.0;
    return double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _recalculateStats() {
    double weight = _safeParseDouble(_currentWeightDisplay);
    double height = _safeParseDouble(_heightController.text);
    double adjustment = _safeParseDouble(_adjustmentController.text);

    _calculatedAge = _selectedDate != null ? _calculateAge(_selectedDate!) : 0;

    if (weight > 0 && height > 0 && _calculatedAge > 0) {
      if (_gender == 'M') {
        _bmr = (10 * weight) + (6.25 * height) - (5 * _calculatedAge) + 5;
      } else {
        _bmr = (10 * weight) + (6.25 * height) - (5 * _calculatedAge) - 161;
      }
      _tdee = _bmr * _activityLevel;
      _finalTarget = _tdee + adjustment;
    } else {
      _bmr = 0;
      _tdee = 0;
      _finalTarget = 0;
    }

    if (_finalTarget.isNaN) _finalTarget = 0;
    if (_bmr.isNaN) _bmr = 0;
    if (_tdee.isNaN) _tdee = 0;

    if (mounted) setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate = _selectedDate ?? DateTime(2000);
    DateTime tempDate = initialDate;
    final l10n = AppLocalizations.of(context)!;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builderContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;

        return Container(
          height: 300,
          color: bgColor,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFF5F5F5),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      child: Text(
                        l10n.profileDone,
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Navigator.of(builderContext).pop(),
                    )
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle:
                          TextStyle(color: textColor, fontSize: 22),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: DateTime(1900),
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _selectedDate = tempDate;
        _recalculateStats();
      });
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      AppToast.show(context, l10n.birthDateRequired, isError: true);
      return;
    }

    final db = ref.read(databaseProvider);

    await db.isar.writeTxn(() async {
      final user =
          await db.isar.userSettings.where().findFirst() ?? UserSettings();
      user.name = _nameController.text;
      user.gender = _gender;
      user.birthDate = _selectedDate;

      double newWeight = _safeParseDouble(_currentWeightDisplay);
      user.weight = newWeight;
      user.height = _safeParseDouble(_heightController.text);
      user.activityLevel = _activityLevel;
      user.caloricAdjustment = _safeParseDouble(_adjustmentController.text);

      await db.isar.userSettings.put(user);

      // Update today AND future day logs with the new caloric and macro targets.
      // Past logs are deliberately NOT touched so historical data stays correct.
      if (_finalTarget > 0) {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        final logsToUpdate = await db.isar.dayLogs
            .filter()
            .dateGreaterThan(todayDate, include: true)
            .findAll();
        for (final log in logsToUpdate) {
          log.targetKcal = _finalTarget;
          log.targetProtein = (_finalTarget * user.macroProtein) / 4.0;
          log.targetCarbs = (_finalTarget * user.macroCarbs) / 4.0;
          log.targetFat = (_finalTarget * user.macroFat) / 9.0;
          await db.isar.dayLogs.put(log);
        }
      }
    });

    CloudSyncService(db).syncUserSettings();
    ref.invalidate(dailyLogProvider);

    if (mounted) {
      AppToast.show(context, l10n.profileSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildPremiumAppBar(l10n),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 10, 20, MediaQuery.of(context).padding.bottom + 80),
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHeroCard(l10n),
            const SizedBox(height: 32),

            _buildSectionTitle(l10n.profileSectionPersonal),
            _buildFormGroup(
              isDark: isDark,
              children: [
                _buildCleanTextField(
                  label: l10n.fieldName,
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),
                _buildDivider(isDark),
                _buildDateSelectorTile(l10n),
                _buildDivider(isDark),
                _buildCleanGenderSelector(l10n, isDark),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(l10n.profileSectionBody),
            _buildFormGroup(
              isDark: isDark,
              children: [
                _buildWeightTile(l10n),
                _buildDivider(isDark),
                _buildHeightTile(l10n),
                _buildDivider(isDark),
                _buildCleanActivityDropdown(l10n),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(l10n.profileSectionStrategy),
            _buildFormGroup(
              isDark: isDark,
              children: [
                _buildCleanAdjustmentField(l10n),
                _buildDivider(isDark),
                _buildMacroSettingsTile(context, l10n),
              ],
            ),
            const SizedBox(height: 40), // Espaço generoso antes do botão

            // O botão está agora integrado diretamente no final da lista
            _buildCleanSaveButton(l10n),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // UI COMPONENTS
  // =========================================================================

  PreferredSizeWidget _buildPremiumAppBar(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final userName = _nameController.text.trim();
    return AppBar(
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
            child: const Icon(Icons.person_rounded,
                color: Color(0xFF00E676), size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.navProfile,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  )),
              if (userName.isNotEmpty)
                Text(userName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    )),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Icon(Icons.settings_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.6)),
            tooltip: l10n.configuration,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const SettingsScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: const Color(0xFF00E676).withAlpha(15),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(
          color: const Color(0xFF00E676).withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.dailyGoal.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
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
                _finalTarget.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.kcal,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                  child: _buildMiniStat(l10n.bmr, _bmr.toStringAsFixed(0))),
              Container(
                height: 40,
                width: 1,
                color: Theme.of(context).dividerColor.withAlpha(50),
              ),
              Expanded(
                  child: _buildMiniStat(l10n.tdee, _tdee.toStringAsFixed(0))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
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

  Widget _buildCleanTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
    String? suffixText,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildIconCircle(icon),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixText: suffixText,
                suffixStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  fontWeight: FontWeight.bold,
                ),
              ),
              validator: (v) => v == null || v.isEmpty
                  ? AppLocalizations.of(context)!.required
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectorTile(AppLocalizations l10n) {
    final dateText = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : l10n.profileSelect;

    return InkWell(
      onTap: () => _selectDate(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildIconCircle(Icons.cake_outlined, color: Colors.orangeAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.birthDateLabel,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(120),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (_calculatedAge > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.yearsOld(_calculatedAge),
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightTile(AppLocalizations l10n) {
    return InkWell(
      onTap: _goToWeightHistory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildIconCircle(Icons.monitor_weight_outlined,
                color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.currentWeightLabel,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(120),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _currentWeightDisplay.isNotEmpty
                            ? _currentWeightDisplay
                            : "--",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "kg",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightTile(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildIconCircle(Icons.straighten_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fieldHeight,
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(120),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _heightController,
                        onChanged: (_) => _recalculateStats(),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed:
                              true, // Remove totalmente o padding interno residual
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? AppLocalizations.of(context)!.required
                            : null,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "cm",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanGenderSelector(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildIconCircle(
            _gender == 'M' ? Icons.male : Icons.female,
            color: _gender == 'M' ? Colors.blueAccent : Colors.pinkAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'M', label: Text(l10n.male)),
                ButtonSegment(value: 'F', label: Text(l10n.female)),
              ],
              selected: {_gender},
              onSelectionChanged: (newSet) {
                setState(() => _gender = newSet.first);
                _recalculateStats();
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: const Color(0xFF00E676).withAlpha(30),
                selectedForegroundColor: const Color(0xFF00E676),
                backgroundColor: Colors.transparent,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(10)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanActivityDropdown(AppLocalizations l10n) {
    // Helper para obter o título e subtítulo de cada nível
    Map<double, Map<String, String>> getActivityData(AppLocalizations l10n) {
      return {
        1.2: {
          'title': l10n.activitySedentary,
          'desc': l10n.activitySedentaryDesc
        },
        1.375: {'title': l10n.activityLight, 'desc': l10n.activityLightDesc},
        1.55: {
          'title': l10n.activityModerate,
          'desc': l10n.activityModerateDesc
        },
        1.725: {
          'title': l10n.activityIntense,
          'desc': l10n.activityIntenseDesc
        },
        1.9: {'title': l10n.activityAthlete, 'desc': l10n.activityAthleteDesc},
      };
    }

    final activityData = getActivityData(l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14), // Mantém 14px em vez de 4px!
      child: Row(
        children: [
          _buildIconCircle(Icons.directions_run, color: Colors.orangeAccent),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<double>(
              value: _activityLevel,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
              dropdownColor: Theme.of(context).colorScheme.surface,
              isExpanded: true,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                labelText: l10n.activityLevel,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  fontSize: 12, // Texto da label mais pequeno quando flutua
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 8, bottom: 4),
              ),
              // Como o item fica quando está selecionado e a lista está fechada
              selectedItemBuilder: (BuildContext context) {
                return activityData.keys.map((double value) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      activityData[value]!['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList();
              },
              // Como os itens aparecem na lista aberta (rico e apelativo)
              items: activityData.keys.map((double value) {
                final isSelected = _activityLevel == value;
                return DropdownMenuItem<double>(
                  value: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activityData[value]!['title']!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF00E676)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activityData[value]!['desc']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(120),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _activityLevel = val);
                  _recalculateStats();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanAdjustmentField(AppLocalizations l10n) {
    double currentAdj = _safeParseDouble(_adjustmentController.text);
    Color adjColor = currentAdj < 0
        ? Colors.redAccent
        : (currentAdj > 0
            ? const Color(0xFF00E676)
            : Theme.of(context).colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildIconCircle(Icons.tune, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.caloricAdjustment,
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(120),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: _adjustmentController,
                        keyboardType:
                            const TextInputType.numberWithOptions(signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
                        ],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: adjColor,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onChanged: (_) => _recalculateStats(),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      "kcal",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSettingsTile(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MacroSettingsScreen()),
        ).then((_) => _recalculateStats());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            _buildIconCircle(Icons.pie_chart_outline,
                color: const Color(0xFF00E676)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.macroSettingsTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.macroSettingsSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildIconCircle(IconData icon, {Color? color}) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: effectiveColor.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: effectiveColor),
    );
  }

  Widget _buildCleanSaveButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          foregroundColor: Colors.black,
          elevation: 6,
          shadowColor: const Color(0xFF00E676).withAlpha(100),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _saveProfile,
        child: Text(
          l10n.saveProfile.toUpperCase(),
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
