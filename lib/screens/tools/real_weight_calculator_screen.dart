import 'package:flutter/material.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class RealWeightCalculatorScreen extends StatefulWidget {
  const RealWeightCalculatorScreen({super.key});

  @override
  State<RealWeightCalculatorScreen> createState() =>
      _RealWeightCalculatorScreenState();
}

class _RealWeightCalculatorScreenState
    extends State<RealWeightCalculatorScreen> {
  final _realWeightController = TextEditingController();
  final _scaleWeightController = TextEditingController();
  final _goalWeightController = TextEditingController();
  final _actualRemovedScaleController = TextEditingController();

  double _targetOnScale = 0;
  double _scaleRemovalTheo = 0;
  double _actualRealRemoved = 0;
  double _finalRealWeight = 0;

  void _calculate() {
    double rw =
        double.tryParse(_realWeightController.text.replaceAll(',', '.')) ?? 0;
    double sw =
        double.tryParse(_scaleWeightController.text.replaceAll(',', '.')) ?? 0;
    double gw =
        double.tryParse(_goalWeightController.text.replaceAll(',', '.')) ?? 0;
    double asr = double.tryParse(
            _actualRemovedScaleController.text.replaceAll(',', '.')) ??
        0;

    if (rw > 0 && sw > 0) {
      double ratio = sw / rw;
      setState(() {
        _targetOnScale = gw * ratio;
        _scaleRemovalTheo = sw - _targetOnScale;
        _actualRealRemoved = asr / ratio;
        _finalRealWeight = rw - _actualRealRemoved;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.scale_rounded,
                  color: Color(0xFF00E676), size: 28),
            ),
            const SizedBox(width: 15),
            // CORREÇÃO: Expanded adicionado para evitar overflow no título
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.utilities,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(
                    l10n.toolsRealWeight,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow
                        .ellipsis, // Garante que corta se for muito grande
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(l10n.rwCalibration),
            Row(children: [
              Expanded(
                  child: _buildInput(l10n.rwRealWeightShop,
                      _realWeightController, Icons.shopping_basket)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildInput(l10n.rwScaleWeight, _scaleWeightController,
                      Icons.balance)),
            ]),
            const SizedBox(height: 25),
            _buildSectionTitle(l10n.rwGoal),
            _buildInput(
                l10n.rwGoalWeight, _goalWeightController, Icons.flag_rounded),
            const SizedBox(height: 20),
            _buildResultCard(
              title: l10n.rwInstructions,
              mainValue: "${_targetOnScale.toStringAsFixed(1)}g",
              mainLabel: l10n.rwScaleTarget,
              secondaryValue: "${_scaleRemovalTheo.toStringAsFixed(1)}g",
              secondaryLabel: l10n.rwScaleRemove,
              color: const Color(0xFF00E676),
            ),
            const SizedBox(height: 35),
            _buildSectionTitle(l10n.rwVerification),
            _buildInput(l10n.rwScaleRemovedActual,
                _actualRemovedScaleController, Icons.remove_circle_outline,
                highlight: true),
            const SizedBox(height: 20),
            _buildResultCard(
              title: l10n.rwResultReal,
              mainValue: "${_finalRealWeight.toStringAsFixed(1)}g",
              mainLabel: l10n.rwFinalWeight,
              secondaryValue: "${_actualRealRemoved.toStringAsFixed(1)}g",
              secondaryLabel: l10n.rwRemovedReal,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildInput(
      String label, TextEditingController controller, IconData icon,
      {bool highlight = false}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => _calculate(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            color: highlight ? const Color(0xFF00E676) : Colors.grey, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
              color: highlight ? const Color(0xFF00E676) : Colors.transparent,
              width: 1.5),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String mainValue,
    required String mainLabel,
    required String secondaryValue,
    required String secondaryLabel,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 12),
          Text(mainValue,
              style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold, color: color)),
          Text(mainLabel,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(thickness: 0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text("$secondaryLabel: ",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(secondaryValue,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
