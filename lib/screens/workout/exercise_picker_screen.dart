import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class _ExerciseCategory {
  final String name;
  final Color color;
  final List<String> exercises;
  _ExerciseCategory(this.name, this.color, this.exercises);
}

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  List<_ExerciseCategory> _categories = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _loading = true;
  String? _errorMessage;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final json = await rootBundle.loadString('assets/data/exercises.json');
      final data = jsonDecode(json) as Map<String, dynamic>;
      final cats = (data['categories'] as List).map((c) {
        final colorHex = c['color'] as String;
        final colorVal = int.parse(colorHex);
        return _ExerciseCategory(
          c['name'] as String,
          Color(colorVal),
          List<String>.from(c['exercises'] as List),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Erro ao carregar exercícios: $e';
        });
      }
    }
  }

  List<({String exercise, String category, Color color})> get _filteredResults {
    final query = _searchQuery.toLowerCase().trim();
    final results = <({String exercise, String category, Color color})>[];

    for (final cat in _categories) {
      if (_selectedCategory.isNotEmpty && cat.name != _selectedCategory) {
        continue;
      }
      for (final ex in cat.exercises) {
        if (query.isEmpty || ex.toLowerCase().contains(query)) {
          results.add((exercise: ex, category: cat.name, color: cat.color));
        }
      }
    }
    return results;
  }

  void _pick(String name) => Navigator.pop(context, name);

  void _pickCustom() {
    final query = _searchQuery.trim();
    if (query.isEmpty) return;
    Navigator.pop(context, query);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.exerciseLibraryTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _errorMessage = null;
                          });
                          _loadExercises();
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(isDark),
                    _buildCategoryChips(),
                    const SizedBox(height: 4),
                    Expanded(child: _buildList(colorScheme, isDark)),
                  ],
                ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: l10n.exerciseSearchHint,
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF00E676)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Colors.grey.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          _CategoryChip(
            label: AppLocalizations.of(context)!.allFilter,
            selected: _selectedCategory.isEmpty,
            color: const Color(0xFF00E676),
            onTap: () => setState(() => _selectedCategory = ''),
          ),
          ..._categories.map((cat) => _CategoryChip(
                label: cat.name,
                selected: _selectedCategory == cat.name,
                color: cat.color,
                onTap: () => setState(() => _selectedCategory =
                    _selectedCategory == cat.name ? '' : cat.name),
              )),
        ],
      ),
    );
  }

  Widget _buildList(ColorScheme colorScheme, bool isDark) {
    final results = _filteredResults;
    final showCustom = _searchQuery.trim().isNotEmpty &&
        !results.any((r) =>
            r.exercise.toLowerCase() == _searchQuery.trim().toLowerCase());

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length + (showCustom ? 1 : 0),
      itemBuilder: (context, index) {
        if (showCustom && index == results.length) {
          return _buildCustomTile(isDark);
        }
        final item = results[index];
        return _ExerciseTile(
          name: item.exercise,
          category: item.category,
          categoryColor: item.color,
          onTap: () => _pick(item.exercise),
        );
      },
    );
  }

  Widget _buildCustomTile(bool isDark) {
    return GestureDetector(
      onTap: _pickCustom,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF00E676), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${_searchQuery.trim()}"',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF00E676)),
                  ),
                  Text(AppLocalizations.of(context)!.createCustomExercise,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF00E676)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center, // <-- Força o centro exato
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16), // Removido o vertical
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.1, // Evita margens escondidas da própria fonte
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String name;
  final String category;
  final Color categoryColor;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.name,
    required this.category,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.grey.withValues(alpha: 0.07)
              : Colors.grey.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.fitness_center_rounded,
                  color: categoryColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(category,
                      style: TextStyle(
                          fontSize: 12,
                          color: categoryColor.withValues(alpha: 0.8))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
