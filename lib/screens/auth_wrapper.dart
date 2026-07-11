import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/models/user.dart';
import '../providers/app_providers.dart';
import 'home_wrapper.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  bool _needsOnboardingFor(UserSettings? settings, User? firebaseUser) {
    if (settings == null || settings.birthDate == null) return true;
    if (settings.uid == null) return false;
    return settings.uid != firebaseUser?.uid;
  }

  Future<void> _checkInitialAuth() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    bool loggedIn = firebaseUser != null;
    bool needsOnboarding = false;

    if (loggedIn) {
      final db = ref.read(databaseProvider);
      final settings = await db.isar.userSettings.where().findFirst();
      needsOnboarding = _needsOnboardingFor(settings, firebaseUser);
      if (!needsOnboarding && settings != null && settings.uid == null) {
        await db.isar.writeTxn(() async {
          settings.uid = firebaseUser.uid;
          await db.isar.userSettings.put(settings);
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _needsOnboarding = needsOnboarding;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final isLoggingOut = previous?.value != null && next.value == null;

      if (isLoggingOut && mounted) {
        setState(() {
          _isLoggedIn = false;
          _needsOnboarding = false;
        });
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    });

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E676)),
        ),
      );
    }

    if (_isLoggedIn) {
      return _needsOnboarding ? const OnboardingScreen() : const HomeWrapper();
    }
    return const LoginScreen();
  }
}