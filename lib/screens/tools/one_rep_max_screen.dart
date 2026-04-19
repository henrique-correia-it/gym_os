import 'package:flutter/material.dart';
import 'package:gym_os/l10n/app_localizations.dart';

class OneRepMaxScreen extends StatefulWidget {
  const OneRepMaxScreen({super.key});

  @override
  State<OneRepMaxScreen> createState() => _OneRepMaxScreenState();
}

class _OneRepMaxScreenState extends State<OneRepMaxScreen> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  

  double _oneRepMax = 0;

  // Carregado no build para ter acesso ao l10n
  List<Map<String, dynamic>> _referenceTable(AppLocalizations l10n) => [
        {'pct': 0.95, 'reps': '2', 'label': l10n.ormPureStrength},
        {
          'pct': 0.90,
          'reps': '3-4',
          'label': l10n.ormPureStrength
        }, // Simplificado ou criar chave especifica se quiser
        {'pct': 0.85, 'reps': '5-6', 'label': l10n.ormHypertrophy},
        {'pct': 0.80, 'reps': '7-8', 'label': l10n.ormHypertrophy},
        {'pct': 0.75, 'reps': '9-10', 'label': l10n.ormHypertrophy},
        {'pct': 0.70, 'reps': '11-12', 'label': l10n.ormEndurance},
        {'pct': 0.65, 'reps': '15', 'label': l10n.ormEndurance},
        {'pct': 0.60, 'reps': '20', 'label': l10n.ormEndurance},
        {'pct': 0.50, 'reps': '30+', 'label': l10n.ormExplosion},
      ];

  void _calculate() {
    double weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
    double reps =
        double.tryParse(_repsController.text.replaceAll(',', '.')) ?? 0;

    if (weight > 0 && reps > 0) {
      setState(() {
        if (reps == 1) {
          _oneRepMax = weight;
        } else {
          _oneRepMax = weight * (1 + (reps / 30.0));
        }
      });
    } else {
      setState(() {
        _oneRepMax = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Color(0xFFFF5252), size: 24),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.utilities,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(l10n.oneRmTitle,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.testPerformed,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          l10n.weightKg,
                          _weightController,
                          Icons.fitness_center,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInput(
                          l10n.reps,
                          _repsController,
                          Icons.repeat_rounded,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            if (_oneRepMax > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.maxStrength,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${_oneRepMax.toStringAsFixed(1)} kg",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 30),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.intensity,
                        style: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(l10n.loadAndReps,
                        style: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _referenceTable(l10n).length,
                itemBuilder: (context, index) {
                  final item = _referenceTable(l10n)[index];
                  final pct = item['pct'] as double;
                  final reps = item['reps'] as String;
                  final label = item['label'] as String;
                  final weight = _oneRepMax * pct;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _getColorForPct(pct).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${(pct * 100).toInt()}%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _getColorForPct(pct),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${weight.toStringAsFixed(1)} kg",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                reps,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                l10n.reps.toLowerCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 60,
                          color: colorScheme.onSurface.withValues(alpha: 0.1)),
                      const SizedBox(height: 15),
                      Text(
                        l10n.ormFillData,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Color _getColorForPct(double pct) {
    if (pct >= 0.90) return const Color(0xFFFF5252);
    if (pct >= 0.80) return Colors.orange;
    if (pct >= 0.70) return Colors.amber;
    if (pct >= 0.60) return Colors.teal;
    return Colors.blue;
  }

  Widget _buildInput(String label, TextEditingController controller,
      IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _calculate(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFFFF5252), size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.grey.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
