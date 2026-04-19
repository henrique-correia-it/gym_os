import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_os/l10n/app_localizations.dart';
import 'package:gym_os/providers/daily_log_provider.dart';
import 'package:isar/isar.dart';

import '../data/models/user.dart';
import '../providers/app_providers.dart';
import '../utils/app_toast.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import 'home_wrapper.dart';
import 'login_screen.dart';
import 'meals_settings_screen.dart'; // Alterado para ir direto para o LoginScreen no logout

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // ===========================================================================
  // LÓGICA DE SINCRONIZAÇÃO COM A NUVEM E AUTENTICAÇÃO
  // ===========================================================================

  Future<void> _backupToCloud(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      AppToast.show(context, l10n.settingsBackupInProgress);

      final db = ref.read(databaseProvider);
      final syncService = CloudSyncService(db);

      await syncService.backupToCloud();

      if (context.mounted) {
        AppToast.show(context, l10n.settingsBackupSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, l10n.settingsBackupError(e.toString()));
      }
    }
  }

  Future<void> _restoreFromCloud(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importWarningTitle),
        content: Text(l10n.settingsRestoreWarningMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.yesRestore,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (context.mounted) {
          AppToast.show(context, l10n.settingsRestoreInProgress);
        }

        final db = ref.read(databaseProvider);
        final syncService = CloudSyncService(db);

        await syncService.restoreFromCloud();

        // =========================================================
        // Limpar a cache do Riverpod
        // =========================================================
        ref.invalidate(userSettingsProvider);
        ref.invalidate(themeStringProvider);
        ref.invalidate(localeProvider);

        if (context.mounted) {
          AppToast.show(context, l10n.dataRestored);

          // Reinicia a interface navegando de novo para a Home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeWrapper()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(context, l10n.settingsRestoreError(e.toString()));
        }
      }
    }
  }

  // AQUI ESTÁ A LÓGICA DE LOGOUT CORRIGIDA
  Future<void> _handleLogout(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLogoutTitle),
        content: Text(l10n.settingsLogoutMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.settingsLogoutTitle,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Aceder à base de dados local
        final db = ref.read(databaseProvider);

        // 2. Limpar ABSOLUTAMENTE TUDO do Isar
        await db.isar.writeTxn(() async {
          await db.isar.clear();
        });

        // 3. Limpar o estado do Riverpod para não ficar nada em memória
        ref.invalidate(userSettingsProvider);
        ref.invalidate(themeStringProvider);
        ref.invalidate(localeProvider);
        ref.invalidate(dailyLogProvider);
        ref.invalidate(selectedDateProvider);
        ref.invalidate(navIndexProvider);

        // 4. Terminar sessão no Firebase / Google
        final authService = AuthService();
        await authService.signOut();

        // 5. FORÇAR A NAVEGAÇÃO PARA O LOGIN (A correção!)
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          // Toast de erro importado do teu utils
          AppToast.show(context, l10n.settingsLogoutError(e.toString()));
        }
      }
    }
  }
  // ===========================================================================
  // INTERFACE VISUAL (MODERNIZADA)
  // ===========================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeStringProvider);
    final currentLocale = ref.watch(localeProvider);
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
                child: const Icon(Icons.settings_suggest_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.preferences.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settings,
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        physics: const BouncingScrollPhysics(), // Scroll mais suave
        children: [
          // --- 1. SECÇÃO ASPETO (TEMA) ---
          _buildSectionHeader(context, l10n.appearance),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                _buildThemeCard(
                  context,
                  ref,
                  label: l10n.themeLight,
                  value: 'light',
                  current: currentTheme,
                  icon: Icons.wb_sunny_rounded,
                ),
                _buildThemeCard(
                  context,
                  ref,
                  label: l10n.themeDark,
                  value: 'dark',
                  current: currentTheme,
                  icon: Icons.nightlight_round,
                ),
                _buildThemeCard(
                  context,
                  ref,
                  label: l10n.themeAmoled,
                  value: 'amoled',
                  current: currentTheme,
                  icon: Icons.bedtime_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- 2. SECÇÃO PERSONALIZAÇÃO ---
          _buildSectionHeader(context, l10n.settingsPersonalization),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.restaurant_menu_rounded,
                  iconColor: Colors.deepOrangeAccent,
                  title: l10n.meals,
                  subtitle: l10n.settingsMealsSub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MealsSettingsScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- 3. SECÇÃO GERAL ---
          _buildSectionHeader(context, l10n.general),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.language,
                  iconColor: Colors.blueAccent,
                  title: l10n.language,
                  subtitle: currentLocale.languageCode == 'pt'
                      ? '🇵🇹 Português'
                      : (currentLocale.languageCode == 'en'
                          ? '🇺🇸 English (DEV)'
                          : '🇪🇸 Español (DEV)'),
                  onTap: () => _showLanguageSelector(
                      context, ref, currentLocale.languageCode),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- 3. SECÇÃO DADOS (CLOUD SYNC) ---
          _buildSectionHeader(context, l10n.dataBackup),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                // ---- AUTO-SYNC TOGGLE (Modernizado) ----
                Consumer(
                  builder: (context, ref, _) {
                    final userAsync = ref.watch(userSettingsProvider);
                    final autoSync = userAsync.valueOrNull?.autoSync ?? true;
                    return _buildSettingsTile(
                      context,
                      icon: Icons.sync_rounded,
                      iconColor: const Color(0xFF00E676),
                      title: l10n.settingsAutoSyncTitle,
                      subtitle: l10n.settingsAutoSyncSubtitle,
                      hideTrailingIcon: true,
                      trailing: Switch(
                        value: autoSync,
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF00E676),
                        inactiveThumbColor:
                            colorScheme.onSurface.withOpacity(0.4),
                        inactiveTrackColor:
                            colorScheme.onSurface.withOpacity(0.1),
                        onChanged: (val) async {
                          final db = ref.read(databaseProvider);
                          await db.isar.writeTxn(() async {
                            final user =
                                await db.isar.userSettings.where().findFirst();
                            if (user != null) {
                              user.autoSync = val;
                              await db.isar.userSettings.put(user);
                            }
                          });
                          CloudSyncService(db).syncUserSettings(force: true);
                        },
                      ),
                    );
                  },
                ),
                Divider(
                    height: 1,
                    indent: 64,
                    color: colorScheme.outline.withOpacity(0.08)),
                _buildSettingsTile(
                  context,
                  icon: Icons.cloud_upload_rounded,
                  iconColor: Colors.blueAccent, // Cor mais standard de cloud
                  title: l10n.settingsBackupDataTitle,
                  subtitle: l10n.settingsBackupDataSubtitle,
                  hideTrailingIcon: true,
                  onTap: () => _backupToCloud(context, ref),
                ),
                Divider(
                    height: 1,
                    indent: 64,
                    color: colorScheme.outline.withOpacity(0.08)),
                _buildSettingsTile(
                  context,
                  icon: Icons.cloud_download_rounded,
                  iconColor: Colors.orangeAccent, // Alerta visual de restauro
                  title: l10n.settingsRestoreDataTitle,
                  subtitle: l10n.settingsRestoreDataSubtitle,
                  hideTrailingIcon: true,
                  onTap: () => _restoreFromCloud(context, ref, l10n),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- 4. SECÇÃO CONTA (NOVA) ---
          _buildSectionHeader(context, l10n.settingsAccountSection),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.logout_rounded,
                  iconColor: Colors.redAccent,
                  title: l10n.settingsLogoutItemTitle,
                  subtitle: l10n.settingsLogoutItemSubtitle,
                  isDestructive:
                      true, // Nova flag para dar cor vermelha ao texto
                  hideTrailingIcon: true,
                  onTap: () => _handleLogout(context, ref, l10n),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- 5. SECÇÃO SOBRE (MODERNIZADA) ---
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest.withOpacity(0.3)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                // Logo Circular Desenhado
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.fitness_center_rounded,
                        color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 16),

                // Nome da App e Versão
                const Text(
                  "GymOS",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.settingsVersionLabel(l10n.versionAlpha.toUpperCase()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES DE IDIOMA ---
  Future<void> _showLanguageSelector(
      BuildContext context, WidgetRef ref, String currentLang) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
        context: context,
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.language,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageOption(ctx, ref, "pt", "🇵🇹 Português",
                      l10n.settingsLanguageMain, currentLang),
                  _buildLanguageOption(ctx, ref, "en", "🇺🇸 English",
                      l10n.settingsLanguageDev, currentLang,
                      isDev: true),
                  _buildLanguageOption(ctx, ref, "es", "🇪🇸 Español",
                      l10n.settingsLanguageDev, currentLang,
                      isDev: true),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, String code,
      String name, String desc, String currentLang,
      {bool isDev = false}) {
    final isSelected = code == currentLang;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(context); // Fechar logo o painel

          if (isDev) {
            final newL10n = lookupAppLocalizations(Locale(code));
            AppToast.show(context, newL10n.settingsLanguageDevWarning);
          }

          if (code != currentLang) {
            final db = ref.read(databaseProvider);
            await db.isar.writeTxn(() async {
              final user = await db.isar.userSettings.where().findFirst() ??
                  UserSettings();
              user.language = code;
              await db.isar.userSettings.put(user);
            });
            CloudSyncService(db).syncUserSettings();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00E676).withOpacity(0.15)
                      : colorScheme.onSurface.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.language_rounded,
                  color: isSelected
                      ? const Color(0xFF00E676)
                      : colorScheme.onSurface.withOpacity(0.4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 16,
                              color: isSelected
                                  ? const Color(0xFF00E676)
                                  : colorScheme.onSurface,
                            )),
                        if (isDev) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text("DEV",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent)),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface
                                .withOpacity(isSelected ? 0.7 : 0.4))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR: CABEÇALHO DE SECÇÃO ---
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR: CARTÃO DE TEMA ---
  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String value,
    required String current,
    required IconData icon,
  }) {
    final isSelected = current == value;
    final colorScheme = Theme.of(context).colorScheme;

    // Cores consoante modo claro escuro para texto
    final bool isAppDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedTextColor = isAppDark ? Colors.white54 : Colors.black54;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          ref.read(themeStringProvider.notifier).state = value;
          final db = ref.read(databaseProvider);
          await db.isar.writeTxn(() async {
            final user = await db.isar.userSettings.where().findFirst() ??
                UserSettings();
            user.themePersistence = value;
            await db.isar.userSettings.put(user);
          });
          CloudSyncService(db).syncUserSettings();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone que ganha vida ao selecionar
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : unselectedTextColor.withOpacity(0.6),
                  size: isSelected ? 24 : 22,
                ),
              ),
              const SizedBox(height: 8),
              // Label com formatação dinâmica
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? colorScheme.primary : unselectedTextColor,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: isSelected ? 13 : 12,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR: LINHA DE OPÇÕES (TILE) ---
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool hideTrailingIcon = false, // Permite esconder a seta
    bool isDestructive = false, // Permite pintar o texto de vermelho
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.redAccent.withOpacity(0.1)
                      : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: isDestructive ? Colors.redAccent : iconColor,
                    size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? Colors.redAccent
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDestructive
                              ? Colors.redAccent.withOpacity(0.7)
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (!hideTrailingIcon)
                Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
