import 'package:flutter/material.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:gym_os/screens/tools/cereal_calculator_screen.dart';
import 'package:gym_os/screens/tools/load_tracker_screen.dart';
import 'package:gym_os/screens/tools/one_rep_max_screen.dart';
import 'tools/batch_calculator_screen.dart';
import 'tools/real_weight_calculator_screen.dart';
import 'tools/batch_manager_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
              child: const Icon(Icons.handyman_rounded,
                  color: Color(0xFF00E676), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tools,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    )),
                Text(l10n.toolsSubtitle,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        children: [
          _SectionHeader(label: l10n.navDiet),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            title: l10n.toolsBatchCalc,
            subtitle: l10n.toolsBatchCalcSub,
            icon: Icons.soup_kitchen_outlined,
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const BatchCalculatorScreen())),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            title: l10n.toolsBatchManager,
            subtitle: l10n.toolsBatchManagerSub,
            icon: Icons.edit_calendar_rounded,
            color: Colors.teal,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const BatchManagerScreen())),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            title: l10n.toolsCereal,
            subtitle: l10n.toolsCerealSub,
            icon: Icons.breakfast_dining_rounded,
            color: Colors.amber.shade800,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const CerealCalculatorScreen())),
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: l10n.navWorkout),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            title: l10n.toolsLoadTracker,
            subtitle: l10n.toolsLoadTrackerSub,
            icon: Icons.trending_up_rounded,
            color: Colors.indigoAccent,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const LoadTrackerScreen())),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            title: l10n.toolsOneRepMax,
            subtitle: l10n.toolsOneRepMaxSub,
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFF5252),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const OneRepMaxScreen())),
          ),
          const SizedBox(height: 12),
          _buildToolCard(
            context,
            title: l10n.toolsRealWeight,
            subtitle: l10n.toolsRealWeightSub,
            icon: Icons.scale_outlined,
            color: const Color(0xFF00E676),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const RealWeightCalculatorScreen())),
          ),

        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(20)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
