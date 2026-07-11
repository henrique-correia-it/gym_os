import 'package:flutter/material.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../providers/dashboard_provider.dart';

class DashboardCalorieCard extends StatelessWidget {
  final DashboardData data;

  const DashboardCalorieCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Lógica Matemática
    double remainingKcal = data.targetKcal - data.eatenKcal;
    bool isExceeded = remainingKcal < 0;

    // Paleta de Cores Sóbria e Precisa
    const Color primaryColor = Color(0xFF00C853);
    const Color alertColor = Color(0xFFFF5252);
    final Color activeColor = isExceeded ? alertColor : primaryColor;

    return Container(
      padding: const EdgeInsets.all(
          20), // Reduzido de 24 para dar mais espaço interior
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // SECÇÃO PRINCIPAL: Gráfico Circular à esquerda, Macros à direita
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Gráfico Circular de Alta Precisão (Ligeiramente menor para caber em ecrãs pequenos)
              SizedBox(
                width: 110, // Largura controlada
                child: CircularPercentIndicator(
                  radius: 55.0, // Reduzido de 65.0
                  lineWidth: 7.0,
                  percent: data.progress.clamp(0.0, 1.0),
                  animation: true,
                  animationDuration: 1200,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.06),
                  progressColor: activeColor,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        remainingKcal.abs().toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24, // Reduzido ligeiramente
                          height: 1.0,
                          letterSpacing: -1.0,
                          color:
                              isExceeded ? alertColor : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isExceeded
                            ? l10n.exceeded.toUpperCase()
                            : l10n.remaining.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 20), // Espaçamento reduzido de 32 para 20

              // 2. Lista de Macros Ultra-Limpa
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrecisionMacroRow(
                      context: context,
                      label: l10n.protein,
                      value: data.eatenProtein,
                      target: data.targetProtein,
                      color: const Color(0xFF29B6F6),
                      unit: l10n.unitG,
                    ),
                    const SizedBox(height: 16), // Espaçamento ajustado
                    _buildPrecisionMacroRow(
                      context: context,
                      label: l10n.carbs,
                      value: data.eatenCarbs,
                      target: data.targetCarbs,
                      color: const Color(0xFFFFB74D),
                      unit: l10n.unitG,
                    ),
                    const SizedBox(height: 16),
                    _buildPrecisionMacroRow(
                      context: context,
                      label: l10n.fat,
                      value: data.eatenFat,
                      target: data.targetFat,
                      color: const Color(0xFFE57373),
                      unit: l10n.unitG,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 3. Rodapé Embutido
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFooterStat(
                    context: context,
                    label: l10n.goal,
                    value: "${data.targetKcal.toInt()}",
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _buildFooterStat(
                    context: context,
                    label: l10n.consumed,
                    value: "${data.eatenKcal.toInt()}",
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // COMPONENTES PRIVADOS DE ALTA PRECISÃO VISUAL

  Widget _buildPrecisionMacroRow({
    required BuildContext context,
    required String label,
    required double value,
    required double target,
    required Color color,
    required String unit,
  }) {
    double percent = (target > 0) ? (value / target).clamp(0.0, 1.0) : 0.0;
    bool isOverTarget = value > target && target > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // FLEXIBLE: Impede que o texto "Proteína/Hidratos" rebente o layout
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow:
                          TextOverflow.ellipsis, // Adiciona "..." se não couber
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Valores
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "${value.toInt()}",
                  style: TextStyle(
                    fontSize: 13, // Ajustado para não colidir
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isOverTarget
                        ? const Color(0xFFFF5252)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  " / ${target.toInt()}$unit",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 4.0,
          percent: percent,
          padding: EdgeInsets.zero,
          barRadius: const Radius.circular(4),
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.12),
          animation: true,
          animationDuration: 1000,
        ),
      ],
    );
  }

  Widget _buildFooterStat({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
