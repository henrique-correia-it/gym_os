import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:percent_indicator/percent_indicator.dart'; // REQUIRED FOR MACRO RINGS
import '../data/models/nutrition.dart';
import '../providers/app_providers.dart';
import '../utils/text_normalize.dart';
import '../services/cloud_sync_service.dart';
import '../services/label_scanner_service.dart';
import 'barcode_scanner_screen.dart';
import '../utils/app_toast.dart';

class CreateFoodScreen extends ConsumerStatefulWidget {
  final FoodItem? foodToEdit; // Se for null, é CRIAÇÃO.
  final String? initialName;

  const CreateFoodScreen({super.key, this.foodToEdit, this.initialName});

  @override
  ConsumerState<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends ConsumerState<CreateFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _kcalController;
  late TextEditingController _protController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  String _unit = 'g';
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final f = widget.foodToEdit;

    _nameController =
        TextEditingController(text: f?.name ?? widget.initialName ?? "");

    // CORREÇÃO: Usar toStringAsFixed(1) para permitir ver decimais nas Kcal ao editar
    _kcalController =
        TextEditingController(text: f != null ? f.kcal.toStringAsFixed(1) : "");
    _protController = TextEditingController(
        text: f != null ? f.protein.toStringAsFixed(1) : "");
    _carbsController = TextEditingController(
        text: f != null ? f.carbs.toStringAsFixed(1) : "");
    _fatController =
        TextEditingController(text: f != null ? f.fat.toStringAsFixed(1) : "");

    _unit = f?.unit ?? 'g';
  }

  Future<void> _saveFood() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final db = ref.read(databaseProvider);
    final isEditing = widget.foodToEdit != null;

    final query =
        db.isar.foodItems.filter().nameEqualTo(name, caseSensitive: false);
    final existingFood = await query.findFirst();

    if (existingFood != null &&
        (!isEditing || existingFood.id != widget.foodToEdit!.id)) {
      if (!mounted) return;

      final bool? replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.duplicateFoodTitle),
          content: Text(l10n.duplicateFoodMsg(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.replace,
                  style: const TextStyle(
                      color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (replace == null || replace == false) return;
    }

    late FoodItem savedFood;
    await db.isar.writeTxn(() async {
      final food = FoodItem()
        ..name = name
        ..searchName = normalizeForSearch(name)
        ..kcal = double.tryParse(_kcalController.text.replaceAll(',', '.')) ?? 0
        ..protein =
            double.tryParse(_protController.text.replaceAll(',', '.')) ?? 0
        ..carbs =
            double.tryParse(_carbsController.text.replaceAll(',', '.')) ?? 0
        ..fat = double.tryParse(_fatController.text.replaceAll(',', '.')) ?? 0
        ..unit = _unit
        ..source = "User";

      if (isEditing) {
        food.id = widget.foodToEdit!.id;
      } else if (existingFood != null) {
        food.id = existingFood.id;
      }

      await db.isar.foodItems.put(food);
      savedFood = food;
    });
    CloudSyncService(db).syncFood(savedFood);

    if (mounted) {
      AppToast.show(context, l10n.foodSaved);
      Navigator.pop(context, true);
    }
  }

  Future<void> _scanLabel() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScanSourcePicker(),
    );
    if (source == null) return;

    NutritionScanResult? result;

    if (source == 'barcode') {
      // Scanner live — não precisa de _isScanning (tem o próprio ecrã)
      if (!mounted) return;
      result = await Navigator.push<NutritionScanResult>(
        context,
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );
      if (!mounted) return;
      if (result == null) {
        AppToast.show(context, 'Produto não encontrado. Tenta fotografar o rótulo nutricional.');
        return;
      }
    } else if (source == 'barcode_gallery') {
      setState(() => _isScanning = true);
      try {
        final scanner = LabelScannerService();
        result = await scanner.scanBarcodeFromGallery();
        if (!mounted) return;
        if (result == null) {
          AppToast.show(context, 'Código de barras não encontrado. Tenta outra imagem ou fotografa o rótulo nutricional.');
          return;
        }
      } finally {
        if (mounted) setState(() => _isScanning = false);
      }
    } else {
      setState(() => _isScanning = true);
      try {
        final scanner = LabelScannerService();
        result = source == 'camera'
            ? await scanner.scanFromCamera()
            : await scanner.scanFromGallery();
        if (!mounted) return;
        if (result == null) return;
        debugPrint('[OCR raw]\n${result.rawText}');
        if (!result.hasAnyValue) {
          AppToast.show(context, 'Nenhum valor nutricional detetado. Tenta outra foto.');
          return;
        }
      } finally {
        if (mounted) setState(() => _isScanning = false);
      }
    }

    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScanResultSheet(result: result!),
    );

    if (confirmed == true) {
      if (result.productName != null && _nameController.text.trim().isEmpty) {
        _nameController.text = result.productName!;
      }
      if (result.kcal != null) _kcalController.text = result.kcal!.toStringAsFixed(1);
      if (result.protein != null) _protController.text = result.protein!.toStringAsFixed(1);
      if (result.carbs != null) _carbsController.text = result.carbs!.toStringAsFixed(1);
      if (result.fat != null) _fatController.text = result.fat!.toStringAsFixed(1);
      if (mounted) AppToast.show(context, '${result.foundCount} valores preenchidos automaticamente!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodToEdit != null;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 10, left: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00C853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myFoodsLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEditing ? l10n.editFoodTitle : l10n.createFoodTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10),
            child: _isScanning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF00E676),
                    ),
                  )
                : GestureDetector(
                    onTap: _scanLabel,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00E676).withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Color(0xFF00E676),
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==== INPUT NOME DO ALIMENTO ====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: Colors.orangeAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.foodName,
                              hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  fontSize: 16),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.next,
                            validator: (v) => v!.isEmpty ? l10n.required : null,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_special,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                widget.foodToEdit?.source == 'API'
                                    ? l10n.onlineLabel
                                    : l10n.myFoodsLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ==== INÍCIO ÁREA MODAL-LIKE ====
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Segmented Button (Porção) - Integrado
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                              value: 'g',
                              label: Text(l10n.unit100g,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              icon: const Icon(Icons.scale_rounded)),
                          ButtonSegment(
                              value: 'un',
                              label: Text(l10n.unit1Unit,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              icon: const Icon(Icons.egg_rounded)),
                        ],
                        selected: {_unit},
                        onSelectionChanged: (newSet) =>
                            setState(() => _unit = newSet.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: const Color(0xFF00E676),
                          selectedForegroundColor: Colors.white,
                          backgroundColor: colorScheme.surface,
                          side: BorderSide(color: Colors.grey.withAlpha(20)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Kcal Destacado ao Centro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IntrinsicWidth(
                          child: TextField(
                            controller: _kcalController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00E676),
                              height: 1.0,
                            ),
                            decoration: InputDecoration(
                              hintText: "0",
                              hintStyle: TextStyle(
                                  color:
                                      const Color(0xFF00E676).withOpacity(0.5)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            l10n.unitKcal.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Header Macros Mágicos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pie_chart_rounded,
                        color: colorScheme.onSurface.withOpacity(0.4),
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.macrosHint.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      )),
                ],
              ),
              const SizedBox(height: 24),

              // Inputs de Macros Mágicos (Círculos PercentIndicator)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: _buildMacroRingInput(
                          l10n.protein, _protController, Colors.blueAccent)),
                  Expanded(
                      child: _buildMacroRingInput(
                          l10n.carbs, _carbsController, Colors.orangeAccent)),
                  Expanded(
                      child: _buildMacroRingInput(
                          l10n.fat, _fatController, Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 48),

              const SizedBox(height: 48),

              // Botão Guardar Premium
              Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00C853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _saveFood,
                  child:
                      Text(isEditing ? l10n.saveChanges : l10n.createFoodAction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          )),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES MODERNIZADOS ---

  Widget _buildMacroRingInput(
      String label, TextEditingController controller, Color color) {
    return CircularPercentIndicator(
      radius: 40.0,
      lineWidth: 5.0,
      percent: 1.0,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor:
          color.withOpacity(0.2), // Simulando o anel da visualização do modal
      backgroundColor: Colors.transparent,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IntrinsicWidth(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, height: 1.0),
              decoration: const InputDecoration(
                hintText: "0",
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context)!.unitG,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet de escolha de fonte ─────────────────────────────────────────

Widget _sectionLabel(String text, ColorScheme cs) => Padding(
  padding: const EdgeInsets.only(bottom: 2),
  child: Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: cs.onSurface.withValues(alpha: 0.4),
    ),
  ),
);

class _ScanSourcePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.07),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Digitalizar produto',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Lê o código de barras ou fotografa a tabela nutricional',
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 20),
          _sectionLabel('Código de barras', colorScheme),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Câmera',
                  color: const Color(0xFFFFB74D),
                  onTap: () => Navigator.pop(context, 'barcode'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceOption(
                  icon: Icons.image_search_rounded,
                  label: 'Galeria',
                  color: const Color(0xFFFFB74D),
                  onTap: () => Navigator.pop(context, 'barcode_gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Tabela nutricional', colorScheme),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Câmera',
                  color: const Color(0xFF00E676),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeria',
                  color: const Color(0xFF00E676),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Sheet de confirmação do scan ──────────────────────────────────────

class _ScanResultSheet extends StatelessWidget {
  final NutritionScanResult result;
  const _ScanResultSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (result.isFromBarcode
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFF00E676))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  result.isFromBarcode
                      ? Icons.qr_code_scanner_rounded
                      : Icons.document_scanner_rounded,
                  color: result.isFromBarcode
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFF00E676),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.isFromBarcode ? 'Produto encontrado' : 'Rótulo detetado',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      result.isFromBarcode
                          ? (result.productName ?? 'Produto sem nome')
                          : '${result.foundCount} de 4 valores encontrados',
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid de valores 2x2
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _ValueTile('Kcal', result.kcal, const Color(0xFF00C853), 'kcal')),
                  const SizedBox(width: 10),
                  Expanded(child: _ValueTile('Proteína', result.protein, const Color(0xFF29B6F6), 'g')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _ValueTile('Hidratos', result.carbs, const Color(0xFFFFB74D), 'g')),
                  const SizedBox(width: 10),
                  Expanded(child: _ValueTile('Gordura', result.fat, const Color(0xFFE57373), 'g')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (result.foundCount < 4)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Os valores em falta terão de ser preenchidos manualmente.',
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.45)),
              ),
            ),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.15)),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Usar estes valores',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  final String unit;

  const _ValueTile(this.label, this.value, this.color, this.unit);

  @override
  Widget build(BuildContext context) {
    final found = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: found
            ? color.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: found
              ? color.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            found ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: found
                ? color
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25),
          ),
          const SizedBox(height: 6),
          Text(
            found ? '${value!.toStringAsFixed(1)}$unit' : '—',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: found
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
