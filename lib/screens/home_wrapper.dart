import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:gym_os/screens/dashboard_screen.dart';
import 'package:gym_os/screens/planner_screen.dart';
import 'package:gym_os/screens/profile_screen.dart';
import 'package:gym_os/screens/tools_screen.dart';
import 'package:gym_os/screens/workout/workout_plan_list_screen.dart';
import '../providers/app_providers.dart';

class HomeWrapper extends ConsumerStatefulWidget {
  const HomeWrapper({super.key});

  @override
  ConsumerState<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends ConsumerState<HomeWrapper> {
  late final PageController _pageController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    final current = ref.read(navIndexProvider);
    if (current == index) return;
    ref.read(navIndexProvider.notifier).state = index;
    _isAnimating = true;
    _pageController
        .animateToPage(index,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut)
        .then((_) => _isAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = ref.watch(navIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sincroniza o PageController quando o índice muda externamente
    // (ex: botões no dashboard que saltam para outra tab)
    ref.listen<int>(navIndexProvider, (_, next) {
      if (!_isAnimating &&
          _pageController.hasClients &&
          _pageController.page?.round() != next) {
        _pageController.jumpToPage(next);
      }
    });

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (!_isAnimating) {
            ref.read(navIndexProvider.notifier).state = index;
          }
        },
        children: const [
          DashboardScreen(),
          PlannerScreen(),
          WorkoutPlanListScreen(),
          ToolsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _NavBar(
        currentIndex: currentIndex,
        onTap: _onNavTap,
        l10n: l10n,
        isDark: isDark,
        colorScheme: colorScheme,
      ),
    );
  }
}

// ─── Floating Nav Bar ─────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final AppLocalizations l10n;
  final bool isDark;
  final ColorScheme colorScheme;

  const _NavBar({
    required this.currentIndex,
    required this.onTap,
    required this.l10n,
    required this.isDark,
    required this.colorScheme,
  });

  static const _activeColor = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final items = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.restaurant_outlined, Icons.restaurant_rounded, l10n.navDiet),
      (Icons.fitness_center_outlined, Icons.fitness_center_rounded, l10n.navWorkout),
      (Icons.handyman_outlined, Icons.handyman_rounded, l10n.navTools),
      (Icons.person_outline, Icons.person_rounded, l10n.navProfile),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surface.withValues(alpha: 0.85)
                  : colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.onSurface
                    .withValues(alpha: isDark ? 0.1 : 0.07),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final total = constraints.maxWidth;
                final n = items.length;
                // selected flex=2, others flex=1 → total flex = n+1
                final selW = total * 2 / (n + 1);
                final unselW = total / (n + 1);
                return Row(
                  children: List.generate(n, (i) {
                    final (iconOut, iconFill, label) = items[i];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeInOutCubic,
                      width: currentIndex == i ? selW : unselW,
                      child: _NavItem(
                        index: i,
                        itemCount: n,
                        currentIndex: currentIndex,
                        iconOutlined: iconOut,
                        iconFilled: iconFill,
                        label: label,
                        onTap: onTap,
                        activeColor: _activeColor,
                        colorScheme: colorScheme,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int itemCount;
  final int currentIndex;
  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
  final void Function(int) onTap;
  final Color activeColor;
  final ColorScheme colorScheme;

  const _NavItem({
    required this.index,
    required this.itemCount,
    required this.currentIndex,
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
    required this.onTap,
    required this.activeColor,
    required this.colorScheme,
  });

  BorderRadius _pillRadius(bool isSelected) {
    const outer = Radius.circular(30);
    const inner = Radius.circular(22);
    if (!isSelected) return BorderRadius.circular(22);
    if (index == 0) {
      return const BorderRadius.only(
          topLeft: outer, bottomLeft: outer, topRight: inner, bottomRight: inner);
    }
    if (index == itemCount - 1) {
      return const BorderRadius.only(
          topRight: outer, bottomRight: outer, topLeft: inner, bottomLeft: inner);
    }
    return BorderRadius.circular(22);
  }

  EdgeInsets _pillPadding(bool isSelected) {
    const v = 10.0;
    const inner = 14.0;
    const outerSel = 16.0;
    if (!isSelected) return const EdgeInsets.symmetric(horizontal: 14, vertical: v);
    if (index == 0) return const EdgeInsets.fromLTRB(outerSel, v, inner, v);
    if (index == itemCount - 1) return const EdgeInsets.fromLTRB(inner, v, outerSel, v);
    return const EdgeInsets.symmetric(horizontal: 18, vertical: v);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: _pillPadding(isSelected),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.13)
              : Colors.transparent,
          borderRadius: _pillRadius(isSelected),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected
                  ? activeColor
                  : colorScheme.onSurface.withValues(alpha: 0.45),
              size: 22,
            ),
            Flexible(
              child: ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: isSelected ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
