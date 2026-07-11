import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADICIONADO PARA O ROLLBACK
import 'package:gym_os/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../providers/app_providers.dart';
import 'home_wrapper.dart';
import 'onboarding_screen.dart';

import '../providers/dashboard_provider.dart';
import '../providers/daily_log_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _statusText;
  bool _isButtonPressed = false;

  late AnimationController _floatingController;
  late AnimationController _bgController;
  late AnimationController _enterController;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _bgController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _statusText = l10n.loginStatusConnecting;
    });

    final user = await _authService.signInWithGoogle();

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginErrorCancelled),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final db = ref.read(databaseProvider);
      final syncService = CloudSyncService(db);

      final cloudDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (cloudDoc.exists) {
        if (mounted) {
          setState(() => _statusText = l10n.loginStatusDownloading);
        }
        await syncService.restoreFromCloud();

        ref.invalidate(userSettingsProvider);
        ref.invalidate(themeStringProvider);
        ref.invalidate(localeProvider);
        ref.invalidate(dashboardProvider);
        ref.invalidate(dailyLogProvider);
      } else {
        if (mounted) {
          setState(() => _statusText = l10n.loginStatusCreatingProfile);
        }
        // conta nova: não faz backup ainda, o onboarding vai gravar os dados
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        final destination = cloudDoc.exists ? const HomeWrapper() : const OnboardingScreen();
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // CORREÇÃO CRÍTICA: ROLLBACK DA AUTENTICAÇÃO
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginErrorSync),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final buttonMaxWidth = size.width - 80;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) => _buildAnimatedMeshBackground(size),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildStaggeredElement(
                      interval:
                          const Interval(0.0, 0.4, curve: Curves.easeOutBack),
                      // Removido o Transform.translate que usava o _floatingController
                      child: _buildGlowingLogo(),
                    ),
                    const SizedBox(height: 50),
                    _buildStaggeredElement(
                      interval:
                          const Interval(0.2, 0.6, curve: Curves.easeOutExpo),
                      child: const Text(
                        'GYMOS',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 10,
                        ),
                      ),
                    ),
                    _buildStaggeredElement(
                      interval:
                          const Interval(0.3, 0.7, curve: Curves.easeOutExpo),
                      child: Container(
                        height: 4,
                        width: 70,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E676).withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    ),
                    _buildStaggeredElement(
                      interval:
                          const Interval(0.4, 0.8, curve: Curves.easeOutExpo),
                      child: Text(
                        l10n.loginSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                    _buildStaggeredElement(
                      interval:
                          const Interval(0.6, 1.0, curve: Curves.easeOutExpo),
                      child: _buildMorphingGlassButton(buttonMaxWidth),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: _isLoading
                            ? Center(
                                key: ValueKey(_statusText),
                                child: Text(
                                  (_statusText ?? l10n.loginStatusPreparing)
                                      .toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF00E676)
                                        .withOpacity(0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredElement(
      {required Interval interval, required Widget child}) {
    return AnimatedBuilder(
      animation: _enterController,
      builder: (context, childWidget) {
        final animation =
            CurvedAnimation(parent: _enterController, curve: interval);
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildAnimatedMeshBackground(Size size) {
    final moveX = math.sin(_bgController.value * math.pi * 2) * 50;
    final moveY = math.cos(_bgController.value * math.pi * 2) * 50;

    return Stack(
      children: [
        Positioned(
          top: -100 + moveY,
          left: -50 + moveX,
          child: Container(
            width: 350,
            height: 350,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00E676),
            ),
          ),
        ),
        Positioned(
          bottom: 150 - moveY,
          right: -100 - moveX,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E676).withOpacity(0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingLogo() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00E676).withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.25),
            blurRadius: 50,
            spreadRadius: 10,
          )
        ],
      ),
      child: const Icon(
        Icons.fitness_center_rounded,
        size: 75,
        color: Color(0xFF00E676),
      ),
    );
  }

  Widget _buildMorphingGlassButton(double maxWidth) {
    final double buttonWidth = _isLoading ? 75.0 : maxWidth;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isButtonPressed = true),
      onTapUp: (_) {
        setState(() => _isButtonPressed = false);
        if (!_isLoading) _handleLogin();
      },
      onTapCancel: () => setState(() => _isButtonPressed = false),
      child: AnimatedScale(
        scale: _isButtonPressed && !_isLoading ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCirc,
          width: buttonWidth,
          height: 75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isLoading
                  ? const Color(0xFF00E676).withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: _isLoading ? 2 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00E676),
                      strokeWidth: 3,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 26,
                          width: 26,
                        ),
                        const SizedBox(width: 18),
                        Text(
                          AppLocalizations.of(context)!.loginContinueWithGoogle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
