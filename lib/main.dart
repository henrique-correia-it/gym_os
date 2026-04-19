import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. ADICIONAR ESTA IMPORTAÇÃO
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:isar/isar.dart';
import 'firebase_options.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'data/database.dart';
import 'data/models/user.dart';
import 'providers/app_providers.dart';
import 'screens/auth_wrapper.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. BLOQUEAR A ROTAÇÃO DO ECRÃ (Apenas Modo Retrato)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. INICIALIZAR O FIREBASE PRIMEIRO
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
        debugPrint('Firebase inicializado com sucesso!');
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase: $e');
  }

  // 2. INICIALIZAR O ISAR
  final dbService = DatabaseService();
  try {
    await dbService.init();
  } catch (e, stackTrace) {
    debugPrint('ERRO CRÍTICO AO INICIAR DB: $e');
    debugPrint(stackTrace.toString());
  }

  // 3. LER TEMA GUARDADO ANTES DE RENDERIZAR (evita flash de tema errado)
  String initialTheme = 'dark';
  try {
    final user = await dbService.isar.userSettings.where().findFirst();
    final persisted = user?.themePersistence ?? '';
    if (persisted == 'light' || persisted == 'dark' || persisted == 'amoled') {
      initialTheme = persisted;
    }
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(dbService),
        themeStringProvider.overrideWith((ref) => initialTheme),
      ],
      child: const GymOSApp(),
    ),
  );
}

class GymOSApp extends ConsumerWidget {
  const GymOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeString = ref.watch(themeStringProvider);
    final currentLocale = ref.watch(localeProvider);

    ThemeMode mode;
    if (themeModeString == "light") {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.dark;
    }

    return MaterialApp(
      title: 'GymOS',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: mode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme(themeModeString),
      
      // 3. AQUI ESTÁ A MUDANÇA: Substituímos o HomeWrapper pelo AuthWrapper
      home: const AuthWrapper(), 
    );
  }
}