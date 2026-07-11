import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

import '../data/models/user.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../services/cloud_sync_service.dart';
import 'home_wrapper.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  static const int _totalPages = 5;

  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _adjustCtrl = TextEditingController(text: '0');

  String _gender = 'M';
  DateTime? _birthDate;
  double _activityLevel = 1.375;
  String _selectedTheme = 'dark';
  bool _isSaving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _adjustCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_page) {
      case 1:
        return _nameCtrl.text.trim().isNotEmpty;
      case 2:
        return _birthDate != null &&
            _heightCtrl.text.isNotEmpty &&
            _weightCtrl.text.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _save();
    }
  }

  void _prev() => _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);

    final weight =
        double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 70.0;
    final height =
        double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 175.0;
    final adjust =
        double.tryParse(_adjustCtrl.text.replaceAll(',', '.')) ?? 0.0;

    await db.isar.writeTxn(() async {
      final user =
          await db.isar.userSettings.where().findFirst() ?? UserSettings();
      user.uid = ref.read(authStateProvider).value?.uid;
      user.name = _nameCtrl.text.trim();
      user.gender = _gender;
      user.birthDate = _birthDate;
      user.height = height;
      user.weight = weight;
      user.activityLevel = _activityLevel;
      user.caloricAdjustment = adjust;
      user.themePersistence = _selectedTheme;
      await db.isar.userSettings.put(user);

      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final existing = await db.isar.weightEntrys
          .filter()
          .dateEqualTo(today)
          .findFirst();
      final entry = existing ?? (WeightEntry()..date = today);
      entry.weight = weight;
      await db.isar.weightEntrys.put(entry);
    });

    ref.read(themeStringProvider.notifier).state = _selectedTheme;
    CloudSyncService(db).syncUserSettings();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeWrapper()),
        (_) => false,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.watch(themeStringProvider); // rebuild when theme changes
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_page > 0) _ProgressBar(current: _page, total: _totalPages),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(l10n: l10n),
                  _buildNamePage(l10n),
                  _buildBodyPage(l10n),
                  _buildActivityPage(l10n),
                  _buildThemePage(l10n),
                ],
              ),
            ),
            _BottomBar(
              page: _page,
              totalPages: _totalPages,
              canContinue: _canContinue,
              isSaving: _isSaving,
              onNext: _next,
              onPrev: _prev,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 1 — NAME + GENDER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNamePage(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
              title: l10n.onboardingNameTitle,
              subtitle: l10n.onboardingNameSubtitle),
          const SizedBox(height: 32),
          _FieldLabel(l10n.fieldName),
          const SizedBox(height: 8),
          _AppTextField(
            controller: _nameCtrl,
            hint: l10n.onboardingNameHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 28),
          _FieldLabel(l10n.onboardingGender),
          const SizedBox(height: 12),
          Row(
            children: [
              _GenderCard(
                value: 'M',
                label: l10n.male,
                icon: Icons.male_rounded,
                selected: _gender,
                onTap: (v) => setState(() => _gender = v),
              ),
              const SizedBox(width: 12),
              _GenderCard(
                value: 'F',
                label: l10n.female,
                icon: Icons.female_rounded,
                selected: _gender,
                onTap: (v) => setState(() => _gender = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 2 — BODY DATA
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBodyPage(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
              title: l10n.onboardingBodyTitle,
              subtitle: l10n.onboardingBodySubtitle),
          const SizedBox(height: 28),
          _FieldLabel(l10n.birthDate),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showDatePicker,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _birthDate != null
                      ? cs.primary.withOpacity(0.5)
                      : cs.onSurface.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: _birthDate != null
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.38),
                      size: 18),
                  const SizedBox(width: 12),
                  Text(
                    _birthDate != null
                        ? DateFormat('dd MMM yyyy').format(_birthDate!)
                        : l10n.onboardingSelectDate,
                    style: TextStyle(
                      color: _birthDate != null
                          ? cs.onSurface
                          : cs.onSurface.withOpacity(0.38),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(l10n.fieldHeight),
                    const SizedBox(height: 8),
                    _AppTextField(
                      controller: _heightCtrl,
                      hint: '175',
                      suffix: 'cm',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(l10n.currentWeight),
                    const SizedBox(height: 8),
                    _AppTextField(
                      controller: _weightCtrl,
                      hint: '70',
                      suffix: 'kg',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final cs = Theme.of(context).colorScheme;
    DateTime tempDate = _birthDate ?? DateTime(2000);

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 290,
        color: cs.surface,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                child: Text(AppLocalizations.of(context)!.confirm,
                    style: TextStyle(color: cs.primary)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                maximumDate: DateTime.now()
                    .subtract(const Duration(days: 365 * 10)),
                minimumDate: DateTime(1930),
                onDateTimeChanged: (d) => tempDate = d,
              ),
            ),
          ],
        ),
      ),
    );

    if (mounted) setState(() => _birthDate = tempDate);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 3 — ACTIVITY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActivityPage(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final levels = [
      (1.2, l10n.activitySedentary, Icons.weekend_rounded),
      (1.375, l10n.activityLight, Icons.directions_walk_rounded),
      (1.55, l10n.activityModerate, Icons.directions_run_rounded),
      (1.725, l10n.activityIntense, Icons.sports_rounded),
      (1.9, l10n.activityAthlete, Icons.emoji_events_rounded),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
              title: l10n.onboardingActivityTitle,
              subtitle: l10n.onboardingActivitySubtitle),
          const SizedBox(height: 20),
          ...levels.map((item) {
            final isSelected = _activityLevel == item.$1;
            return GestureDetector(
              onTap: () => setState(() => _activityLevel = item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withOpacity(0.12)
                      : cs.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(item.$3,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.38),
                        size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(item.$2,
                          style: TextStyle(
                            color: isSelected
                                ? cs.onSurface
                                : cs.onSurface.withOpacity(0.7),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 15,
                          )),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: cs.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          _FieldLabel(l10n.caloricAdjustment),
          const SizedBox(height: 8),
          _AppTextField(
            controller: _adjustCtrl,
            hint: '0',
            suffix: 'kcal',
            keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: false),
            helperText: l10n.adjustmentHint,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 4 — THEME
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildThemePage(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final themes = [
      ('dark', l10n.themeDark, Icons.nightlight_round,
          'O clássico modo escuro, suave para os olhos'),
      ('amoled', l10n.themeAmoled, Icons.brightness_2_rounded,
          'Preto puro, ideal para ecrãs AMOLED'),
      ('light', l10n.themeLight, Icons.wb_sunny_rounded,
          'Modo claro para ambientes iluminados'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
              title: l10n.onboardingThemeTitle,
              subtitle: l10n.onboardingThemeSubtitle),
          const SizedBox(height: 24),
          ...themes.map((item) {
            final isSelected = _selectedTheme == item.$1;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedTheme = item.$1);
                ref.read(themeStringProvider.notifier).state = item.$1;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withOpacity(0.1)
                      : cs.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary.withOpacity(0.15)
                            : cs.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.$3,
                          color: isSelected
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.38),
                          size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2,
                              style: TextStyle(
                                color: isSelected
                                    ? cs.onSurface
                                    : cs.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                          const SizedBox(height: 2),
                          Text(item.$4,
                              style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.38),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: cs.primary, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBWIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _WelcomePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final features = [
      (Icons.restaurant_menu_rounded, l10n.onboardingFeature1),
      (Icons.show_chart_rounded, l10n.onboardingFeature2),
      (Icons.fitness_center_rounded, l10n.onboardingFeature3),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.primary.withOpacity(0.25)),
            ),
            child: Icon(Icons.fitness_center_rounded,
                color: cs.primary, size: 38),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.onboardingWelcomeTitle,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.55),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.$1, color: cs.primary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Text(f.$2,
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.7),
                            fontSize: 15)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 4),
      child: Row(
        children: List.generate(total - 1, (i) {
          final filled = i < current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < total - 2 ? 6 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: filled
                    ? cs.primary
                    : cs.onSurface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool canContinue;
  final bool isSaving;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final AppLocalizations l10n;

  const _BottomBar({
    required this.page,
    required this.totalPages,
    required this.canContinue,
    required this.isSaving,
    required this.onNext,
    required this.onPrev,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = page == totalPages - 1;
    final label = page == 0
        ? l10n.onboardingStart
        : isLast
            ? l10n.onboardingFinish
            : l10n.onboardingNext;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Row(
        children: [
          if (page > 0) ...[
            GestureDetector(
              onTap: onPrev,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: cs.onSurface.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.arrow_back_rounded,
                    color: cs.onSurface.withOpacity(0.6)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: canContinue && !isSaving ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  disabledBackgroundColor: cs.primary.withOpacity(0.25),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2.5))
                    : Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(title,
            style: TextStyle(
                color: cs.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.2)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: TextStyle(
                color: cs.onSurface.withOpacity(0.5),
                fontSize: 14,
                height: 1.45)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: TextStyle(
            color: cs.onSurface.withOpacity(0.54),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6));
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final String? helperText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _AppTextField({
    required this.controller,
    this.hint,
    this.suffix,
    this.helperText,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      onChanged: onChanged,
      style: TextStyle(color: cs.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.2)),
        suffixText: suffix,
        suffixStyle: TextStyle(color: cs.onSurface.withOpacity(0.38)),
        helperText: helperText,
        helperStyle: TextStyle(
            color: cs.onSurface.withOpacity(0.38), fontSize: 11),
        filled: true,
        fillColor: cs.onSurface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final String selected;
  final ValueChanged<String> onTap;

  const _GenderCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primary.withOpacity(0.12)
                : cs.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.onSurface.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withOpacity(0.38),
                  size: 30),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.54),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
