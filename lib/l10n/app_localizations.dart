import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// Main screen title
  ///
  /// In pt, this message translates to:
  /// **'Painel'**
  String get dashboardTitle;

  /// Meals section header
  ///
  /// In pt, this message translates to:
  /// **'Refeições'**
  String get meals;

  /// Tools screen title
  ///
  /// In pt, this message translates to:
  /// **'Ferramentas'**
  String get tools;

  /// Tools screen subtitle
  ///
  /// In pt, this message translates to:
  /// **'Utilidades'**
  String get utilities;

  /// Body weight label
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get weight;

  /// Button to view history
  ///
  /// In pt, this message translates to:
  /// **'Ver histórico'**
  String get history;

  /// Body Mass Index
  ///
  /// In pt, this message translates to:
  /// **'IMC'**
  String get imc;

  /// Button to add food
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Alimento'**
  String get addFood;

  /// Button to view daily log
  ///
  /// In pt, this message translates to:
  /// **'Ver Diário'**
  String get viewDiary;

  /// Warning when day is not editable
  ///
  /// In pt, this message translates to:
  /// **'Apenas Leitura'**
  String get readOnly;

  /// Weight tool title
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Peso'**
  String get toolsWeightHistory;

  /// Weight tool description
  ///
  /// In pt, this message translates to:
  /// **'Regista e acompanha a tua evolução corporal'**
  String get toolsWeightHistorySub;

  /// Batch cooking tool title
  ///
  /// In pt, this message translates to:
  /// **'Calculadora de Marmitas'**
  String get toolsBatchCalc;

  /// Batch cooking tool description
  ///
  /// In pt, this message translates to:
  /// **'Calcula macros de comida cozinhada'**
  String get toolsBatchCalcSub;

  /// Cereal tool title
  ///
  /// In pt, this message translates to:
  /// **'Calculadora de Papas'**
  String get toolsCereal;

  /// Cereal tool description
  ///
  /// In pt, this message translates to:
  /// **'Mistura perfeita de Nestum/Cerelac e Líquidos'**
  String get toolsCerealSub;

  /// Workout tool title
  ///
  /// In pt, this message translates to:
  /// **'Plano de Treino'**
  String get toolsWorkout;

  /// Workout tool description
  ///
  /// In pt, this message translates to:
  /// **'Gere as tuas rotinas e exporta para PDF'**
  String get toolsWorkoutSub;

  /// Navigation label for home screen
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// Navigation label for diet screen
  ///
  /// In pt, this message translates to:
  /// **'Dieta'**
  String get navDiet;

  /// Navigation label for workout screen
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get navWorkout;

  /// Navigation label for tools
  ///
  /// In pt, this message translates to:
  /// **'Ferram.'**
  String get navTools;

  /// Navigation label for profile
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// Generic error label
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get error;

  /// Cancel button in caps
  ///
  /// In pt, this message translates to:
  /// **'CANCELAR'**
  String get cancel;

  /// Save button in caps
  ///
  /// In pt, this message translates to:
  /// **'SALVAR'**
  String get save;

  /// Delete button in caps
  ///
  /// In pt, this message translates to:
  /// **'APAGAR'**
  String get delete;

  /// Confirm button
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR'**
  String get confirm;

  /// Required field validation message
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get required;

  /// Remaining calories
  ///
  /// In pt, this message translates to:
  /// **'restam'**
  String get remaining;

  /// Exceeded calories
  ///
  /// In pt, this message translates to:
  /// **'excedido'**
  String get exceeded;

  /// Caloric goal
  ///
  /// In pt, this message translates to:
  /// **'Meta'**
  String get goal;

  /// Consumed calories
  ///
  /// In pt, this message translates to:
  /// **'Consumido'**
  String get consumed;

  /// Protein macronutrient
  ///
  /// In pt, this message translates to:
  /// **'Proteína'**
  String get protein;

  /// Carbohydrate macronutrient
  ///
  /// In pt, this message translates to:
  /// **'Hidratos'**
  String get carbs;

  /// Fat macronutrient
  ///
  /// In pt, this message translates to:
  /// **'Gordura'**
  String get fat;

  /// Short label for Protein
  ///
  /// In pt, this message translates to:
  /// **'P'**
  String get proteinShort;

  /// Short label for Carbs
  ///
  /// In pt, this message translates to:
  /// **'H'**
  String get carbsShort;

  /// Short label for Fat
  ///
  /// In pt, this message translates to:
  /// **'G'**
  String get fatShort;

  /// Placeholder when no meals
  ///
  /// In pt, this message translates to:
  /// **'Sem refeições registadas'**
  String get noMealsRegistered;

  /// Confirmation dialog title
  ///
  /// In pt, this message translates to:
  /// **'Apagar Refeição?'**
  String get deleteMealTitle;

  /// Confirmation message
  ///
  /// In pt, this message translates to:
  /// **'Vais remover \'{name}\' deste dia.'**
  String deleteMealMessage(Object name);

  /// Success toast for removing meal
  ///
  /// In pt, this message translates to:
  /// **'Refeição removida'**
  String get mealRemoved;

  /// Error toast for removing
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover'**
  String get errorRemoving;

  /// Edit title
  ///
  /// In pt, this message translates to:
  /// **'Editar {name}'**
  String edit(Object name);

  /// Quantity label
  ///
  /// In pt, this message translates to:
  /// **'Quantidade ({unit})'**
  String quantity(Object unit);

  /// Success toast for update
  ///
  /// In pt, this message translates to:
  /// **'Atualizado!'**
  String get updated;

  /// Meal type
  ///
  /// In pt, this message translates to:
  /// **'Pequeno-almoço'**
  String get mealBreakfast;

  /// Meal type
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get mealLunch;

  /// Meal type
  ///
  /// In pt, this message translates to:
  /// **'Lanche'**
  String get mealSnack;

  /// Meal type
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get mealDinner;

  /// Meal type
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get mealOthers;

  /// Search bar placeholder
  ///
  /// In pt, this message translates to:
  /// **'O que vais comer hoje?'**
  String get searchPlaceholder;

  /// Message when no results
  ///
  /// In pt, this message translates to:
  /// **'Pesquisa alimentos online ou\nna tua base de dados.'**
  String get searchEmptyTitle;

  /// Create food button
  ///
  /// In pt, this message translates to:
  /// **'Criar \'{name}\''**
  String createFood(Object name);

  /// API food badge
  ///
  /// In pt, this message translates to:
  /// **'Online'**
  String get onlineLabel;

  /// Local food badge
  ///
  /// In pt, this message translates to:
  /// **'Meus Alimentos'**
  String get myFoodsLabel;

  /// Swipe action for API foods
  ///
  /// In pt, this message translates to:
  /// **'IMPORTAR & EDITAR'**
  String get importAndEdit;

  /// Swipe action for local foods
  ///
  /// In pt, this message translates to:
  /// **'EDITAR'**
  String get editAction;

  /// Button to add meal
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR AO DIÁRIO'**
  String get addToDiary;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'{name} adicionado!'**
  String foodAdded(Object name);

  /// Toast for deleting food
  ///
  /// In pt, this message translates to:
  /// **'{name} apagado.'**
  String foodDeleted(Object name);

  /// Toast for API import
  ///
  /// In pt, this message translates to:
  /// **'Importado! A abrir editor...'**
  String get imported;

  /// API connection error
  ///
  /// In pt, this message translates to:
  /// **'Erro de conexão: Verifica a internet.'**
  String get errorConnection;

  /// Planner screen subtitle
  ///
  /// In pt, this message translates to:
  /// **'Diário'**
  String get diary;

  /// Planner screen title
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get feeding;

  /// Title when creating
  ///
  /// In pt, this message translates to:
  /// **'Criar Alimento'**
  String get createFoodTitle;

  /// Title when editing
  ///
  /// In pt, this message translates to:
  /// **'Editar Alimento'**
  String get editFoodTitle;

  /// Name field
  ///
  /// In pt, this message translates to:
  /// **'Nome do Alimento'**
  String get foodName;

  /// Unit of measure
  ///
  /// In pt, this message translates to:
  /// **'100g'**
  String get unit100g;

  /// Unit of measure
  ///
  /// In pt, this message translates to:
  /// **'1 Unidade'**
  String get unit1Unit;

  /// Hint above macro fields
  ///
  /// In pt, this message translates to:
  /// **'Macros (Podes usar vírgulas)'**
  String get macrosHint;

  /// Calories label
  ///
  /// In pt, this message translates to:
  /// **'Kcal'**
  String get kcal;

  /// Save edit button
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ALTERAÇÕES'**
  String get saveChanges;

  /// Create button
  ///
  /// In pt, this message translates to:
  /// **'CRIAR ALIMENTO'**
  String get createFoodAction;

  /// Duplicate dialog title
  ///
  /// In pt, this message translates to:
  /// **'Alimento Repetido'**
  String get duplicateFoodTitle;

  /// Dialog message
  ///
  /// In pt, this message translates to:
  /// **'Já existe um registo chamado \'{name}\'.\nDesejas substituir os valores antigos pelos novos?'**
  String duplicateFoodMessage(Object name);

  /// Replace button
  ///
  /// In pt, this message translates to:
  /// **'SUBSTITUIR'**
  String get replace;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'Alimento guardado!'**
  String get foodSaved;

  /// Configuration subtitle
  ///
  /// In pt, this message translates to:
  /// **'Configuração'**
  String get configuration;

  /// Profile screen title
  ///
  /// In pt, this message translates to:
  /// **'Perfil & Metas'**
  String get profileAndGoals;

  /// Daily goal label
  ///
  /// In pt, this message translates to:
  /// **'META DIÁRIA'**
  String get dailyGoal;

  /// Basal metabolic rate
  ///
  /// In pt, this message translates to:
  /// **'Basal (BMR)'**
  String get bmr;

  /// Total daily energy expenditure
  ///
  /// In pt, this message translates to:
  /// **'Gasto Total (TDEE)'**
  String get tdee;

  /// Name field
  ///
  /// In pt, this message translates to:
  /// **'Nome (Apelido)'**
  String get fieldName;

  /// Height field
  ///
  /// In pt, this message translates to:
  /// **'Altura (cm)'**
  String get fieldHeight;

  /// Weight field
  ///
  /// In pt, this message translates to:
  /// **'Peso Atual (kg)'**
  String get currentWeight;

  /// Birth date field
  ///
  /// In pt, this message translates to:
  /// **'Data de Nascimento'**
  String get birthDate;

  /// Validation error
  ///
  /// In pt, this message translates to:
  /// **'Data de nascimento obrigatória!'**
  String get birthDateRequired;

  /// Age in years
  ///
  /// In pt, this message translates to:
  /// **'{count} anos'**
  String years(Object count);

  /// Activity field
  ///
  /// In pt, this message translates to:
  /// **'Nível de Atividade'**
  String get activityLevel;

  /// Activity option
  ///
  /// In pt, this message translates to:
  /// **'Sedentário'**
  String get activitySedentary;

  /// Activity option
  ///
  /// In pt, this message translates to:
  /// **'Leve (1-3x/sem)'**
  String get activityLight;

  /// Activity option
  ///
  /// In pt, this message translates to:
  /// **'Moderado (3-5x/sem)'**
  String get activityModerate;

  /// Activity option
  ///
  /// In pt, this message translates to:
  /// **'Intenso (6-7x/sem)'**
  String get activityIntense;

  /// Activity option
  ///
  /// In pt, this message translates to:
  /// **'Atleta (Bidiário)'**
  String get activityAthlete;

  /// Adjustment field
  ///
  /// In pt, this message translates to:
  /// **'Ajuste Calórico'**
  String get caloricAdjustment;

  /// Caloric adjustment hint
  ///
  /// In pt, this message translates to:
  /// **'Ex: -300 (Cut), +200 (Bulk)'**
  String get adjustmentHint;

  /// Macro settings button
  ///
  /// In pt, this message translates to:
  /// **'Metas de Macronutrientes'**
  String get macroSettings;

  /// Macro button hint
  ///
  /// In pt, this message translates to:
  /// **'Ajustar % de Prot / Carb / Gord'**
  String get macroSettingsHint;

  /// Save profile button
  ///
  /// In pt, this message translates to:
  /// **'GUARDAR PERFIL'**
  String get saveProfile;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'Perfil guardado e meta atualizada!'**
  String get profileSaved;

  /// IMC Status
  ///
  /// In pt, this message translates to:
  /// **'Abaixo'**
  String get imcUnderweight;

  /// IMC Status
  ///
  /// In pt, this message translates to:
  /// **'Normal'**
  String get imcNormal;

  /// IMC Status
  ///
  /// In pt, this message translates to:
  /// **'Sobrepeso'**
  String get imcOverweight;

  /// IMC Status
  ///
  /// In pt, this message translates to:
  /// **'Obesidade'**
  String get imcObese;

  /// Default user name if not set
  ///
  /// In pt, this message translates to:
  /// **'Atleta'**
  String get defaultUserNameAthlete;

  /// Default generic user name
  ///
  /// In pt, this message translates to:
  /// **'Utilizador'**
  String get defaultUserName;

  /// Male gender
  ///
  /// In pt, this message translates to:
  /// **'Masc.'**
  String get male;

  /// Female gender
  ///
  /// In pt, this message translates to:
  /// **'Fem.'**
  String get female;

  /// Macro screen title
  ///
  /// In pt, this message translates to:
  /// **'Divisão de Macros'**
  String get macroDistribution;

  /// Total label
  ///
  /// In pt, this message translates to:
  /// **'Total da Distribuição'**
  String get totalDistribution;

  /// Validation error
  ///
  /// In pt, this message translates to:
  /// **'A soma deve ser exatamente 100%'**
  String get mustBe100;

  /// Save button
  ///
  /// In pt, this message translates to:
  /// **'GUARDAR DEFINIÇÕES'**
  String get saveSettings;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'Metas atualizadas!'**
  String get goalsUpdated;

  /// Settings subtitle
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get preferences;

  /// Settings title
  ///
  /// In pt, this message translates to:
  /// **'Definições'**
  String get settings;

  /// General section
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get general;

  /// Language label
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// Multilingual subtitle
  ///
  /// In pt, this message translates to:
  /// **'Language / Idioma'**
  String get languageSubtitle;

  /// Appearance section
  ///
  /// In pt, this message translates to:
  /// **'Aspeto'**
  String get appearance;

  /// Light theme
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// Dark theme
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// AMOLED theme
  ///
  /// In pt, this message translates to:
  /// **'Preto'**
  String get themeAmoled;

  /// Data section
  ///
  /// In pt, this message translates to:
  /// **'Dados & Backup'**
  String get dataBackup;

  /// Export title
  ///
  /// In pt, this message translates to:
  /// **'Exportar Dados'**
  String get exportData;

  /// Export subtitle
  ///
  /// In pt, this message translates to:
  /// **'Guardar backup num ficheiro'**
  String get exportDataSub;

  /// Import title
  ///
  /// In pt, this message translates to:
  /// **'Importar Dados'**
  String get importData;

  /// Import subtitle
  ///
  /// In pt, this message translates to:
  /// **'Restaurar backup (Apaga atual)'**
  String get importDataSub;

  /// About section
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get about;

  /// Version label
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get version;

  /// Import warning title
  ///
  /// In pt, this message translates to:
  /// **'Atenção!'**
  String get importWarningTitle;

  /// Warning message
  ///
  /// In pt, this message translates to:
  /// **'Isto vai APAGAR todos os dados atuais e substitui-los pelo backup.\nTens a certeza?'**
  String get importWarningMessage;

  /// Confirm restore
  ///
  /// In pt, this message translates to:
  /// **'Sim, Restaurar'**
  String get yesRestore;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'Dados restaurados!\nA reiniciar...'**
  String get dataRestored;

  /// File error
  ///
  /// In pt, this message translates to:
  /// **'O ficheiro está corrompido ou inválido.'**
  String get corruptFile;

  /// Tool title
  ///
  /// In pt, this message translates to:
  /// **'Ajustar Marmitas'**
  String get toolsBatchManager;

  /// Tool description
  ///
  /// In pt, this message translates to:
  /// **'Edita os ingredientes de marmitas já criadas'**
  String get toolsBatchManagerSub;

  /// Tool title
  ///
  /// In pt, this message translates to:
  /// **'Cálculo 1RM (Força)'**
  String get toolsOneRepMax;

  /// Tool description
  ///
  /// In pt, this message translates to:
  /// **'Estima a tua carga máxima e percentagens'**
  String get toolsOneRepMaxSub;

  /// Tool title
  ///
  /// In pt, this message translates to:
  /// **'Progressão de Cargas'**
  String get toolsLoadTracker;

  /// Tool description
  ///
  /// In pt, this message translates to:
  /// **'Monitoriza o teu aumento de força por exercício'**
  String get toolsLoadTrackerSub;

  /// Tool title
  ///
  /// In pt, this message translates to:
  /// **'Calculadora de Peso Real'**
  String get toolsRealWeight;

  /// Tool description
  ///
  /// In pt, this message translates to:
  /// **'Calibra o peso na tua balança baseado no peso real'**
  String get toolsRealWeightSub;

  /// New weight record title
  ///
  /// In pt, this message translates to:
  /// **'Novo Registo'**
  String get newRecord;

  /// Confirm weight button
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR PESO'**
  String get confirmWeight;

  /// Subtitle
  ///
  /// In pt, this message translates to:
  /// **'Evolução'**
  String get evolution;

  /// Title
  ///
  /// In pt, this message translates to:
  /// **'Análise de Peso'**
  String get weightAnalysis;

  /// Register button
  ///
  /// In pt, this message translates to:
  /// **'REGISTAR'**
  String get register;

  /// Empty placeholder
  ///
  /// In pt, this message translates to:
  /// **'Sem registos de peso.'**
  String get noWeightRecords;

  /// History title
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRICO RECENTE'**
  String get recentHistory;

  /// Workouts screen title
  ///
  /// In pt, this message translates to:
  /// **'Meus Treinos'**
  String get myWorkouts;

  /// New workout button
  ///
  /// In pt, this message translates to:
  /// **'NOVO TREINO'**
  String get newWorkout;

  /// Empty placeholder
  ///
  /// In pt, this message translates to:
  /// **'Cria a tua primeira rotina de treino'**
  String get createFirstRoutine;

  /// Workout empty state title
  ///
  /// In pt, this message translates to:
  /// **'Pronto para treinar?'**
  String get workoutEmptyTitle;

  /// Workout empty state subtitle
  ///
  /// In pt, this message translates to:
  /// **'Cria o teu primeiro plano personalizado ou começa rapidamente com um dos nossos templates.'**
  String get workoutEmptySubtitle;

  /// Create workout from scratch button
  ///
  /// In pt, this message translates to:
  /// **'Criar do zero'**
  String get workoutEmptyCreateOwn;

  /// Use template button
  ///
  /// In pt, this message translates to:
  /// **'Usar um template'**
  String get workoutEmptyUseTemplate;

  /// List subtitle
  ///
  /// In pt, this message translates to:
  /// **'Toca para editar ou exportar PDF'**
  String get tapToEdit;

  /// Confirmation title
  ///
  /// In pt, this message translates to:
  /// **'Apagar Plano'**
  String get deletePlanTitle;

  /// Confirmation message
  ///
  /// In pt, this message translates to:
  /// **'Queres mesmo eliminar o \'{name}\'?'**
  String deletePlanMessage(Object name);

  /// Rename title
  ///
  /// In pt, this message translates to:
  /// **'Renomear Sessão'**
  String get renameSession;

  /// Add exercise title
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Exercício'**
  String get addExercise;

  /// Add button
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR'**
  String get add;

  /// Session label
  ///
  /// In pt, this message translates to:
  /// **'SESSÃO'**
  String get session;

  /// Empty placeholder
  ///
  /// In pt, this message translates to:
  /// **'Sem exercícios'**
  String get noExercises;

  /// Button to add first exercise
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Primeiro'**
  String get addFirst;

  /// Add exercise button
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR EXERCÍCIO'**
  String get addExerciseAction;

  /// Load tracker title
  ///
  /// In pt, this message translates to:
  /// **'Cargas'**
  String get loads;

  /// Dropdown hint
  ///
  /// In pt, this message translates to:
  /// **'Seleciona o exercício'**
  String get selectExercise;

  /// New set label
  ///
  /// In pt, this message translates to:
  /// **'NOVA SÉRIE'**
  String get newSet;

  /// Record button
  ///
  /// In pt, this message translates to:
  /// **'REGISTAR PROGRESSO'**
  String get recordProgress;

  /// Chart title
  ///
  /// In pt, this message translates to:
  /// **'EVOLUÇÃO DE CARGA'**
  String get loadEvolution;

  /// Screen title
  ///
  /// In pt, this message translates to:
  /// **'Peso Real'**
  String get realWeight;

  /// Screen title
  ///
  /// In pt, this message translates to:
  /// **'Cálculo 1RM'**
  String get oneRepMaxCalc;

  /// Test label
  ///
  /// In pt, this message translates to:
  /// **'TESTE REALIZADO'**
  String get testPerformed;

  /// Intensity column
  ///
  /// In pt, this message translates to:
  /// **'Intensidade'**
  String get intensity;

  /// Load and reps column
  ///
  /// In pt, this message translates to:
  /// **'Carga & Reps'**
  String get loadAndReps;

  /// Final adjustment title in cereal calculator
  ///
  /// In pt, this message translates to:
  /// **'Ajuste Final & Confirmar'**
  String get finalAdjustment;

  /// Batch cooking tool title
  ///
  /// In pt, this message translates to:
  /// **'Calculadora'**
  String get batchCalcTitle;

  /// Batch cooking adjust mode
  ///
  /// In pt, this message translates to:
  /// **'Ajustar'**
  String get batchCalcAdjust;

  /// Batch cooking normal mode
  ///
  /// In pt, this message translates to:
  /// **'Marmita'**
  String get batchCalcMarmita;

  /// Hint for recipe name
  ///
  /// In pt, this message translates to:
  /// **'Nome da Receita'**
  String get batchCalcNameHint;

  /// Label for portions
  ///
  /// In pt, this message translates to:
  /// **'RENDE'**
  String get batchCalcYield;

  /// Label for doses
  ///
  /// In pt, this message translates to:
  /// **'DOSES'**
  String get batchCalcDoses;

  /// Label for per dose macros
  ///
  /// In pt, this message translates to:
  /// **'POR DOSE'**
  String get batchCalcPerDose;

  /// Header for ingredients
  ///
  /// In pt, this message translates to:
  /// **'Ingredientes'**
  String get batchCalcIngredients;

  /// Count of ingredients
  ///
  /// In pt, this message translates to:
  /// **'{count} itens'**
  String batchCalcItems(Object count);

  /// Add button
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR'**
  String get batchCalcAdd;

  /// Save button
  ///
  /// In pt, this message translates to:
  /// **'GUARDAR AJUSTES'**
  String get batchCalcSaveAdjustments;

  /// Search hint
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar Ingrediente'**
  String get batchCalcSearchIngredient;

  /// Modal title
  ///
  /// In pt, this message translates to:
  /// **'Editar {name}'**
  String batchCalcEditIngredient(Object name);

  /// Error message
  ///
  /// In pt, this message translates to:
  /// **'Adiciona ingredientes primeiro!'**
  String get batchCalcNoIngredients;

  /// Error message
  ///
  /// In pt, this message translates to:
  /// **'Dá um nome à marmita!'**
  String get batchCalcNameRequired;

  /// Error message
  ///
  /// In pt, this message translates to:
  /// **'O número de doses tem de ser maior que 0!'**
  String get batchCalcDosesError;

  /// Label for goal
  ///
  /// In pt, this message translates to:
  /// **'META DE CALORIAS'**
  String get cerealCalcCalorieGoal;

  /// Label for cereal input
  ///
  /// In pt, this message translates to:
  /// **'Cereal'**
  String get cerealCalcCereal;

  /// Label for liquid input
  ///
  /// In pt, this message translates to:
  /// **'Líquido'**
  String get cerealCalcLiquid;

  /// Label for water
  ///
  /// In pt, this message translates to:
  /// **'Água'**
  String get cerealCalcWater;

  /// Placeholder
  ///
  /// In pt, this message translates to:
  /// **'Selecionar'**
  String get cerealCalcSelect;

  /// Switch label
  ///
  /// In pt, this message translates to:
  /// **'Ajustar Volume Líquido?'**
  String get cerealCalcAdjustVolume;

  /// Switch subtitle
  ///
  /// In pt, this message translates to:
  /// **'Define a qtd. total da taça'**
  String get cerealCalcAdjustVolumeSub;

  /// Input label
  ///
  /// In pt, this message translates to:
  /// **'Volume Total'**
  String get cerealCalcTotalVolume;

  /// Section header
  ///
  /// In pt, this message translates to:
  /// **'RECEITA CALCULADA'**
  String get cerealCalcCalculatedRecipe;

  /// Calorie estimate
  ///
  /// In pt, this message translates to:
  /// **'Estimativa: {kcal} kcal'**
  String cerealCalcEstimate(Object kcal);

  /// Error message
  ///
  /// In pt, this message translates to:
  /// **'Configura a receita primeiro!'**
  String get cerealCalcConfigureFirst;

  /// Button label
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR COMO 1 DOSE'**
  String get cerealCalcAddAsDose;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'Receita adicionada (1 un)!'**
  String get cerealCalcAdded;

  /// Modal title
  ///
  /// In pt, this message translates to:
  /// **'Escolher Líquido'**
  String get cerealCalcChooseLiquid;

  /// Modal title
  ///
  /// In pt, this message translates to:
  /// **'Escolher Cereal'**
  String get cerealCalcChooseCereal;

  /// Label for exercise name input
  ///
  /// In pt, this message translates to:
  /// **'Nome do Exercício'**
  String get exerciseName;

  /// Label for sets count
  ///
  /// In pt, this message translates to:
  /// **'Séries'**
  String get sets;

  /// Label for repetitions count
  ///
  /// In pt, this message translates to:
  /// **'Reps'**
  String get reps;

  /// Label for rest time in seconds
  ///
  /// In pt, this message translates to:
  /// **'Descanso (s)'**
  String get restSeconds;

  /// Label for weight in kg
  ///
  /// In pt, this message translates to:
  /// **'Carga (kg)'**
  String get weightKg;

  /// Label for notes field
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get notes;

  /// Button label to add a set
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Série'**
  String get addSet;

  /// Idade em anos
  ///
  /// In pt, this message translates to:
  /// **'{age} anos'**
  String yearsOld(Object age);

  /// Label do input de data
  ///
  /// In pt, this message translates to:
  /// **'Data de Nascimento'**
  String get birthDateLabel;

  /// Label do input de peso
  ///
  /// In pt, this message translates to:
  /// **'Peso Atual (kg)'**
  String get currentWeightLabel;

  /// Título do botão de macros
  ///
  /// In pt, this message translates to:
  /// **'Metas de Macronutrientes'**
  String get macroSettingsTitle;

  /// Subtítulo do botão de macros
  ///
  /// In pt, this message translates to:
  /// **'Ajustar % de Prot / Carb / Gord'**
  String get macroSettingsSubtitle;

  /// Mensagem de duplicado
  ///
  /// In pt, this message translates to:
  /// **'Já existe um registo chamado \'{name}\'. Desejas substituir os valores antigos pelos novos?'**
  String duplicateFoodMsg(Object name);

  /// Origem da comida calculada
  ///
  /// In pt, this message translates to:
  /// **'Marmita Calc'**
  String get sourceMarmita;

  /// Tipo de refeição para ingredientes
  ///
  /// In pt, this message translates to:
  /// **'Ingrediente'**
  String get ingredientType;

  /// Categoria genérica
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get others;

  /// Unidade de quilocalorias
  ///
  /// In pt, this message translates to:
  /// **'kcal'**
  String get unitKcal;

  /// Unidade de gramas
  ///
  /// In pt, this message translates to:
  /// **'g'**
  String get unitG;

  /// Unidade
  ///
  /// In pt, this message translates to:
  /// **'un'**
  String get unitUn;

  /// Título do ecrã de histórico de peso
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Peso'**
  String get weightHistoryTitle;

  /// Mensagem de estado vazio para gráfico de peso
  ///
  /// In pt, this message translates to:
  /// **'Sem dados suficientes para o gráfico.'**
  String get weightHistoryNoData;

  /// Título da ferramenta de gestão de marmitas
  ///
  /// In pt, this message translates to:
  /// **'Gerir Marmitas'**
  String get batchManagerTitle;

  /// Cabeçalho da secção de ingredientes
  ///
  /// In pt, this message translates to:
  /// **'Ingredientes'**
  String get batchManagerIngredients;

  /// Título do ecrã de evolução de cargas
  ///
  /// In pt, this message translates to:
  /// **'Evolução de Cargas'**
  String get loadTrackerTitle;

  /// Label de exercício
  ///
  /// In pt, this message translates to:
  /// **'Exercício'**
  String get loadTrackerExercise;

  /// Label de peso/carga
  ///
  /// In pt, this message translates to:
  /// **'Carga (kg)'**
  String get loadTrackerWeight;

  /// Label de repetições
  ///
  /// In pt, this message translates to:
  /// **'Repetições'**
  String get loadTrackerReps;

  /// Título do gráfico de progresso
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de Evolução'**
  String get loadTrackerChart;

  /// Título do ecrã de calculadora 1RM
  ///
  /// In pt, this message translates to:
  /// **'Calculadora 1RM'**
  String get oneRmTitle;

  /// Botão de calcular 1RM
  ///
  /// In pt, this message translates to:
  /// **'CALCULAR 1RM'**
  String get oneRmCalculate;

  /// Label do resultado 1RM
  ///
  /// In pt, this message translates to:
  /// **'O teu 1RM Estimado'**
  String get oneRmResult;

  /// Instruções da calculadora 1RM
  ///
  /// In pt, this message translates to:
  /// **'Insere uma carga e quantas repetições consegues fazer com ela.'**
  String get oneRmInstructions;

  /// Título da calculadora de peso real
  ///
  /// In pt, this message translates to:
  /// **'Peso Real vs Balança'**
  String get realWeightTitle;

  /// Texto explicativo do peso real
  ///
  /// In pt, this message translates to:
  /// **'Usa isto para calibrar a diferença entre pesagens em jejum e pesagens durante o dia.'**
  String get realWeightExplanation;

  /// Label de peso na balança
  ///
  /// In pt, this message translates to:
  /// **'Peso na Balança'**
  String get realWeightScale;

  /// Label de peso real estimado
  ///
  /// In pt, this message translates to:
  /// **'Peso Real Estimado'**
  String get realWeightTrue;

  /// Título da secção de dieta
  ///
  /// In pt, this message translates to:
  /// **'Dieta'**
  String get dietTitle;

  /// Label de alimentação
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get dietNutrition;

  /// Tipo de refeição pré-treino
  ///
  /// In pt, this message translates to:
  /// **'Pré-Treino'**
  String get mealPreWorkout;

  /// Tipo de refeição pós-treino
  ///
  /// In pt, this message translates to:
  /// **'Pós-Treino'**
  String get mealPostWorkout;

  /// Default new plan name
  ///
  /// In pt, this message translates to:
  /// **'Novo Plano'**
  String get workoutNewPlan;

  /// Default session name prefix
  ///
  /// In pt, this message translates to:
  /// **'Treino'**
  String get workoutSessionDefault;

  /// Rename dialog title
  ///
  /// In pt, this message translates to:
  /// **'Renomear Sessão'**
  String get workoutRename;

  /// Rename dialog hint
  ///
  /// In pt, this message translates to:
  /// **'Nome (ex: Puxar, Pernas)'**
  String get workoutNameHint;

  /// Dialog title
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Exercício'**
  String get workoutAddExerciseTitle;

  /// Input hint
  ///
  /// In pt, this message translates to:
  /// **'Nome do Exercício'**
  String get workoutExerciseName;

  /// Footer text in PDF
  ///
  /// In pt, this message translates to:
  /// **'Gerado por GymOS • Fica forte!'**
  String get workoutPdfFooter;

  /// Toast message
  ///
  /// In pt, this message translates to:
  /// **'Plano guardado com sucesso!'**
  String get workoutSaveSuccess;

  /// Error message
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar'**
  String get workoutSaveError;

  /// Plan name input hint
  ///
  /// In pt, this message translates to:
  /// **'Nome do Plano'**
  String get workoutPlanNameHint;

  /// Button tooltip
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get workoutExportPdf;

  /// Button tooltip
  ///
  /// In pt, this message translates to:
  /// **'Nova Sessão'**
  String get workoutNewSession;

  /// Button tooltip
  ///
  /// In pt, this message translates to:
  /// **'Apagar Sessão'**
  String get workoutDeleteSession;

  /// Button text
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Primeiro'**
  String get workoutAddFirst;

  /// Validation error
  ///
  /// In pt, this message translates to:
  /// **'O plano tem de ter pelo menos 1 dia.'**
  String get workoutMinDays;

  /// Validation error
  ///
  /// In pt, this message translates to:
  /// **'Dá um nome ao plano!'**
  String get workoutNameRequired;

  /// Section 1 Title
  ///
  /// In pt, this message translates to:
  /// **'1. CALIBRAÇÃO (BALANÇA VS REAL)'**
  String get rwCalibration;

  /// Input label
  ///
  /// In pt, this message translates to:
  /// **'Peso Real (Talho)'**
  String get rwRealWeightShop;

  /// Input label
  ///
  /// In pt, this message translates to:
  /// **'Na Tua Balança'**
  String get rwScaleWeight;

  /// Section 2 Title
  ///
  /// In pt, this message translates to:
  /// **'2. O TEU OBJETIVO'**
  String get rwGoal;

  /// Input label
  ///
  /// In pt, this message translates to:
  /// **'Peso Real que queres no final'**
  String get rwGoalWeight;

  /// Card Title
  ///
  /// In pt, this message translates to:
  /// **'INSTRUÇÕES PARA PESAGEM'**
  String get rwInstructions;

  /// Card Label
  ///
  /// In pt, this message translates to:
  /// **'Para quando a balança marcar isto'**
  String get rwScaleTarget;

  /// Card Label
  ///
  /// In pt, this message translates to:
  /// **'Total a retirar na balança'**
  String get rwScaleRemove;

  /// Section 3 Title
  ///
  /// In pt, this message translates to:
  /// **'3. VERIFICAÇÃO FINAL'**
  String get rwVerification;

  /// Input label
  ///
  /// In pt, this message translates to:
  /// **'Quanto retiraste na balança?'**
  String get rwScaleRemovedActual;

  /// Card Title
  ///
  /// In pt, this message translates to:
  /// **'RESULTADO REAL OBTIDO'**
  String get rwResultReal;

  /// Card Label
  ///
  /// In pt, this message translates to:
  /// **'Peso real que ficou no prato'**
  String get rwFinalWeight;

  /// Card Label
  ///
  /// In pt, this message translates to:
  /// **'Peso real retirado'**
  String get rwRemovedReal;

  /// ORM Table Label
  ///
  /// In pt, this message translates to:
  /// **'Força Pura'**
  String get ormPureStrength;

  /// ORM Table Label
  ///
  /// In pt, this message translates to:
  /// **'Hipertrofia'**
  String get ormHypertrophy;

  /// ORM Table Label
  ///
  /// In pt, this message translates to:
  /// **'Resistência'**
  String get ormEndurance;

  /// ORM Table Label
  ///
  /// In pt, this message translates to:
  /// **'Cardio/Explosão'**
  String get ormExplosion;

  /// Empty State
  ///
  /// In pt, this message translates to:
  /// **'Preenche os dados acima\npara gerar a tabela.'**
  String get ormFillData;

  /// Text when sharing file
  ///
  /// In pt, this message translates to:
  /// **'Backup GymOS'**
  String get backupShareText;

  /// Success message when set is saved
  ///
  /// In pt, this message translates to:
  /// **'Série registada!'**
  String get setSaved;

  /// Message when a record is deleted
  ///
  /// In pt, this message translates to:
  /// **'Registo apagado'**
  String get recordDeleted;

  /// Empty state instruction
  ///
  /// In pt, this message translates to:
  /// **'Começa por selecionar um exercício\npara veres o teu progresso.'**
  String get startBySelecting;

  /// Empty state for batch list
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma marmita encontrada'**
  String get batchEmpty;

  /// Title for delete confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Apagar Marmita'**
  String get batchDeleteTitle;

  /// Confirmation message for deleting a batch
  ///
  /// In pt, this message translates to:
  /// **'Tens a certeza que queres eliminar a receita de \'{name}\'?'**
  String batchDeleteConfirm(Object name);

  /// Buton de editar ingredientes
  ///
  /// In pt, this message translates to:
  /// **'Ingredientes (Editar)'**
  String get cerealCalcEditIngredients;

  /// Meal type: Supper/Late Snack
  ///
  /// In pt, this message translates to:
  /// **'Ceia'**
  String get mealSupper;

  /// Menu option to copy meals
  ///
  /// In pt, this message translates to:
  /// **'Copiar refeições para amanhã'**
  String get copyMealsToTomorrow;

  /// Menu option to clear day
  ///
  /// In pt, this message translates to:
  /// **'Limpar dia'**
  String get clearDay;

  /// Dialog title
  ///
  /// In pt, this message translates to:
  /// **'Limpar dia?'**
  String get clearDayTitle;

  /// Dialog message
  ///
  /// In pt, this message translates to:
  /// **'Isto apagará todas as refeições deste dia. Esta ação não pode ser desfeita.'**
  String get clearDayMessage;

  /// Delete all button
  ///
  /// In pt, this message translates to:
  /// **'Apagar Tudo'**
  String get deleteAll;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'Dia limpo com sucesso!'**
  String get dayClearedSuccess;

  /// Error toast
  ///
  /// In pt, this message translates to:
  /// **'Erro ao limpar dia: {error}'**
  String errorClearingDay(Object error);

  /// Dialog title
  ///
  /// In pt, this message translates to:
  /// **'Amanhã já tem registos'**
  String get tomorrowHasRecords;

  /// Dialog message
  ///
  /// In pt, this message translates to:
  /// **'O dia de amanhã já contém refeições. Deseja adicionar as refeições de hoje à lista existente?'**
  String get tomorrowHasRecordsMessage;

  /// Success toast
  ///
  /// In pt, this message translates to:
  /// **'Refeições de hoje copiadas para amanhã com sucesso!'**
  String get mealsCopiedSuccess;

  /// Error toast
  ///
  /// In pt, this message translates to:
  /// **'Erro ao copiar: {error}'**
  String errorCopying(Object error);

  /// Validation error
  ///
  /// In pt, this message translates to:
  /// **'Por favor selecione uma refeição'**
  String get selectMealError;

  /// Error toast
  ///
  /// In pt, this message translates to:
  /// **'Erro ao exportar: {error}'**
  String exportError(Object error);

  /// Error toast
  ///
  /// In pt, this message translates to:
  /// **'Erro ao abrir ficheiro: {error}'**
  String openFileError(Object error);

  /// Search input hint
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar...'**
  String get searchWord;

  /// 1RM max strength label
  ///
  /// In pt, this message translates to:
  /// **'FORÇA MÁXIMA'**
  String get maxStrength;

  /// Mode title
  ///
  /// In pt, this message translates to:
  /// **'Modo de Ajuste Líquido'**
  String get liquidAdjustMode;

  /// Porridge title
  ///
  /// In pt, this message translates to:
  /// **'Papas de {name}'**
  String porridgeOf(Object name);

  /// Toast message when a workout is deleted
  ///
  /// In pt, this message translates to:
  /// **'Treino removido'**
  String get workoutDeleted;

  /// Erro crítico no arranque da base de dados
  ///
  /// In pt, this message translates to:
  /// **'ERRO CRÍTICO AO INICIAR DB: {error}'**
  String criticalDbError(Object error);

  /// Categoria de alimentos favoritos
  ///
  /// In pt, this message translates to:
  /// **'Meus Favoritos'**
  String get myFavorites;

  /// Erro na importação de dados
  ///
  /// In pt, this message translates to:
  /// **'Erro ao importar dados: {error}'**
  String importDataError(Object error);

  /// Mensagem de sucesso ao restaurar backup
  ///
  /// In pt, this message translates to:
  /// **'Backup restaurado com sucesso!'**
  String get backupRestoredSuccess;

  /// Erro fatal no restauro de backup
  ///
  /// In pt, this message translates to:
  /// **'Erro fatal ao restaurar backup: {error}'**
  String fatalRestoreError(Object error);

  /// Versão da aplicação
  ///
  /// In pt, this message translates to:
  /// **'v1.0.0 Alpha'**
  String get versionAlpha;

  /// Mensagem de rodapé nos ecrã de definições
  ///
  /// In pt, this message translates to:
  /// **'Feito com ❤️ para ti'**
  String get madeWithLove;

  /// Nome curto da calculadora de lotes
  ///
  /// In pt, this message translates to:
  /// **'Calc. Lotes'**
  String get batchCalcShort;

  /// Erro de servidor da API
  ///
  /// In pt, this message translates to:
  /// **'Erro no servidor: {code}'**
  String serverError(Object code);

  /// Erro genérico da API
  ///
  /// In pt, this message translates to:
  /// **'GymOS API Erro: {error}'**
  String apiError(Object error);

  /// Nome curto para pequeno-almoço
  ///
  /// In pt, this message translates to:
  /// **'Peq. Almoço'**
  String get breakfastShort;

  /// Description for loginStatusPreparing
  ///
  /// In pt, this message translates to:
  /// **'A preparar o teu ginásio...'**
  String get loginStatusPreparing;

  /// Description for loginStatusConnecting
  ///
  /// In pt, this message translates to:
  /// **'A ligar ao Google...'**
  String get loginStatusConnecting;

  /// Description for loginErrorCancelled
  ///
  /// In pt, this message translates to:
  /// **'Sessão cancelada ou falhou.'**
  String get loginErrorCancelled;

  /// Description for loginStatusDownloading
  ///
  /// In pt, this message translates to:
  /// **'A descarregar o teu progresso...'**
  String get loginStatusDownloading;

  /// Description for loginStatusCreatingProfile
  ///
  /// In pt, this message translates to:
  /// **'A criar o teu perfil GymOS...'**
  String get loginStatusCreatingProfile;

  /// Description for loginErrorSync
  ///
  /// In pt, this message translates to:
  /// **'Erro na sincronização. Verifica a tua ligação e tenta novamente.'**
  String get loginErrorSync;

  /// Description for loginSubtitle
  ///
  /// In pt, this message translates to:
  /// **'THE ULTIMATE FITNESS OS'**
  String get loginSubtitle;

  /// Description for loginContinueWithGoogle
  ///
  /// In pt, this message translates to:
  /// **'CONTINUAR COM GOOGLE'**
  String get loginContinueWithGoogle;

  /// Description for copyMealsTo
  ///
  /// In pt, this message translates to:
  /// **'Copiar Refeições'**
  String get copyMealsTo;

  /// Description for chooseDestinationDay
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o dia de destino para os registos.'**
  String get chooseDestinationDay;

  /// Description for forToday
  ///
  /// In pt, this message translates to:
  /// **'Para Hoje'**
  String get forToday;

  /// Description for forTomorrow
  ///
  /// In pt, this message translates to:
  /// **'Para Amanhã'**
  String get forTomorrow;

  /// Description for targetHasRecordsMessage
  ///
  /// In pt, this message translates to:
  /// **'O dia de {targetName} já contém refeições registadas. Queres adicionar as novas refeições às que já existem?'**
  String targetHasRecordsMessage(Object targetName);

  /// Description for recordsInTarget
  ///
  /// In pt, this message translates to:
  /// **'Registos em {targetName}'**
  String recordsInTarget(Object targetName);

  /// Description for mealsCopiedTargetSuccess
  ///
  /// In pt, this message translates to:
  /// **'Refeições copiadas para {targetName} com sucesso!'**
  String mealsCopiedTargetSuccess(Object targetName);

  /// Description for today
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get today;

  /// Description for tomorrow
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get tomorrow;

  /// Description for cancelAction
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelAction;

  /// Description for macroSmartPresetsTitle
  ///
  /// In pt, this message translates to:
  /// **'ESTRATÉGIAS RÁPIDAS (SMART PRESETS)'**
  String get macroSmartPresetsTitle;

  /// Description for macroDistributionSection
  ///
  /// In pt, this message translates to:
  /// **'DISTRIBUIÇÃO DE MACRONUTRIENTES'**
  String get macroDistributionSection;

  /// Description for macroCalculationBase
  ///
  /// In pt, this message translates to:
  /// **'Calculado com base na tua meta diária de {kcal} kcal.'**
  String macroCalculationBase(Object kcal);

  /// Description for macroStatusPerfect
  ///
  /// In pt, this message translates to:
  /// **'DISTRIBUIÇÃO PERFEITA'**
  String get macroStatusPerfect;

  /// Description for macroStatusExcess
  ///
  /// In pt, this message translates to:
  /// **'EXCESSO DE {percent}%'**
  String macroStatusExcess(Object percent);

  /// Description for macroStatusMissing
  ///
  /// In pt, this message translates to:
  /// **'FALTAM {percent}%'**
  String macroStatusMissing(Object percent);

  /// Description for macroPresetBalanced
  ///
  /// In pt, this message translates to:
  /// **'Equilibrado'**
  String get macroPresetBalanced;

  /// Description for macroPresetHypertrophy
  ///
  /// In pt, this message translates to:
  /// **'Hipertrofia'**
  String get macroPresetHypertrophy;

  /// Description for macroPresetLowCarb
  ///
  /// In pt, this message translates to:
  /// **'Low Carb'**
  String get macroPresetLowCarb;

  /// Description for profileSectionPersonal
  ///
  /// In pt, this message translates to:
  /// **'DADOS PESSOAIS'**
  String get profileSectionPersonal;

  /// Description for profileSectionBody
  ///
  /// In pt, this message translates to:
  /// **'CORPO & ESTILO DE VIDA'**
  String get profileSectionBody;

  /// Description for profileSectionStrategy
  ///
  /// In pt, this message translates to:
  /// **'ESTRATÉGIA NUTRICIONAL'**
  String get profileSectionStrategy;

  /// Description for profileDone
  ///
  /// In pt, this message translates to:
  /// **'Concluído'**
  String get profileDone;

  /// Description for profileSelect
  ///
  /// In pt, this message translates to:
  /// **'Selecionar'**
  String get profileSelect;

  /// Description for activitySedentaryDesc
  ///
  /// In pt, this message translates to:
  /// **'Pouco ou nenhum exercício'**
  String get activitySedentaryDesc;

  /// Description for activityLightDesc
  ///
  /// In pt, this message translates to:
  /// **'Exercício leve 1 a 3 dias/semana'**
  String get activityLightDesc;

  /// Description for activityModerateDesc
  ///
  /// In pt, this message translates to:
  /// **'Exercício moderado 3 a 5 dias/semana'**
  String get activityModerateDesc;

  /// Description for activityIntenseDesc
  ///
  /// In pt, this message translates to:
  /// **'Exercício intenso 6 a 7 dias/semana'**
  String get activityIntenseDesc;

  /// Description for activityAthleteDesc
  ///
  /// In pt, this message translates to:
  /// **'Atleta ou trabalho físico muito pesado'**
  String get activityAthleteDesc;

  /// Description for settingsBackupInProgress
  ///
  /// In pt, this message translates to:
  /// **'A guardar os teus dados na nuvem...'**
  String get settingsBackupInProgress;

  /// Description for settingsBackupSuccess
  ///
  /// In pt, this message translates to:
  /// **'Cópia de segurança concluída com sucesso!'**
  String get settingsBackupSuccess;

  /// Description for settingsBackupError
  ///
  /// In pt, this message translates to:
  /// **'Erro ao guardar na nuvem: {error}'**
  String settingsBackupError(Object error);

  /// Description for settingsRestoreWarningMsg
  ///
  /// In pt, this message translates to:
  /// **'Isto irá substituir os teus dados atuais pelos que estão guardados na tua conta Google. Queres continuar?'**
  String get settingsRestoreWarningMsg;

  /// Description for settingsRestoreInProgress
  ///
  /// In pt, this message translates to:
  /// **'A restaurar os teus dados da nuvem...'**
  String get settingsRestoreInProgress;

  /// Description for settingsRestoreError
  ///
  /// In pt, this message translates to:
  /// **'Erro ao restaurar: {error}'**
  String settingsRestoreError(Object error);

  /// Description for settingsLogoutTitle
  ///
  /// In pt, this message translates to:
  /// **'Terminar Sessão'**
  String get settingsLogoutTitle;

  /// Description for settingsLogoutMessage
  ///
  /// In pt, this message translates to:
  /// **'Tens a certeza que queres terminar a sessão? Isto irá remover os teus dados locais deste dispositivo (os dados na nuvem estão seguros).'**
  String get settingsLogoutMessage;

  /// Description for settingsLogoutError
  ///
  /// In pt, this message translates to:
  /// **'Erro ao terminar sessão: {error}'**
  String settingsLogoutError(Object error);

  /// Description for settingsAutoSyncTitle
  ///
  /// In pt, this message translates to:
  /// **'Sincronização Automática'**
  String get settingsAutoSyncTitle;

  /// Description for settingsAutoSyncSubtitle
  ///
  /// In pt, this message translates to:
  /// **'Guardar alterações na nuvem de forma automática'**
  String get settingsAutoSyncSubtitle;

  /// Description for settingsBackupDataTitle
  ///
  /// In pt, this message translates to:
  /// **'Fazer Cópia de Segurança'**
  String get settingsBackupDataTitle;

  /// Description for settingsBackupDataSubtitle
  ///
  /// In pt, this message translates to:
  /// **'Forçar sincronização de dados com o Google'**
  String get settingsBackupDataSubtitle;

  /// Description for settingsRestoreDataTitle
  ///
  /// In pt, this message translates to:
  /// **'Restaurar Dados da Nuvem'**
  String get settingsRestoreDataTitle;

  /// Description for settingsRestoreDataSubtitle
  ///
  /// In pt, this message translates to:
  /// **'Recuperar dados guardados anteriormente'**
  String get settingsRestoreDataSubtitle;

  /// Description for settingsAccountSection
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get settingsAccountSection;

  /// Description for settingsLogoutItemTitle
  ///
  /// In pt, this message translates to:
  /// **'Terminar Sessão'**
  String get settingsLogoutItemTitle;

  /// Description for settingsLogoutItemSubtitle
  ///
  /// In pt, this message translates to:
  /// **'Sair da tua conta e limpar dados locais'**
  String get settingsLogoutItemSubtitle;

  /// Description for settingsLanguageMain
  ///
  /// In pt, this message translates to:
  /// **'Versão Principal'**
  String get settingsLanguageMain;

  /// Description for settingsLanguageDev
  ///
  /// In pt, this message translates to:
  /// **'Em desenvolvimento'**
  String get settingsLanguageDev;

  /// Description for settingsLanguageDevWarning
  ///
  /// In pt, this message translates to:
  /// **'Aviso: Idioma ainda em desenvolvimento. Algumas traduções vão estar em falta.'**
  String get settingsLanguageDevWarning;

  /// Unknown value
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get unknown;

  /// Title when weight already exists for that day
  ///
  /// In pt, this message translates to:
  /// **'Peso já registado'**
  String get duplicateWeightTitle;

  /// Message when weight already exists
  ///
  /// In pt, this message translates to:
  /// **'Já registaste {weight} kg neste dia. Queres substituir pelo novo valor?'**
  String duplicateWeightMessage(String weight);

  /// Confirmation dialog title for deleting weight
  ///
  /// In pt, this message translates to:
  /// **'Apagar registo?'**
  String get deleteWeightTitle;

  /// Confirmation message for deleting weight
  ///
  /// In pt, this message translates to:
  /// **'Tens a certeza que queres apagar o registo de {date}?'**
  String deleteWeightMessage(String date);

  /// General category
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get generalCategory;

  /// Onboarding start button
  ///
  /// In pt, this message translates to:
  /// **'Começar'**
  String get onboardingStart;

  /// Onboarding next button
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get onboardingNext;

  /// Onboarding finish button
  ///
  /// In pt, this message translates to:
  /// **'Entrar na App'**
  String get onboardingFinish;

  /// Onboarding welcome title
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo\nao GymOS.'**
  String get onboardingWelcomeTitle;

  /// Onboarding welcome subtitle
  ///
  /// In pt, this message translates to:
  /// **'O teu companheiro de treino e nutrição. Vamos configurar tudo em menos de 2 minutos.'**
  String get onboardingWelcomeSubtitle;

  /// Onboarding feature 1
  ///
  /// In pt, this message translates to:
  /// **'Regista as tuas refeições diárias'**
  String get onboardingFeature1;

  /// Onboarding feature 2
  ///
  /// In pt, this message translates to:
  /// **'Acompanha o teu peso e evolução'**
  String get onboardingFeature2;

  /// Onboarding feature 3
  ///
  /// In pt, this message translates to:
  /// **'Gere os teus planos de treino'**
  String get onboardingFeature3;

  /// Onboarding name page title
  ///
  /// In pt, this message translates to:
  /// **'Como te chamas?'**
  String get onboardingNameTitle;

  /// Onboarding name page subtitle
  ///
  /// In pt, this message translates to:
  /// **'Diz-nos o teu nome e género para personalizarmos a tua experiência.'**
  String get onboardingNameSubtitle;

  /// Onboarding name field hint
  ///
  /// In pt, this message translates to:
  /// **'O teu nome ou apelido'**
  String get onboardingNameHint;

  /// Onboarding gender label
  ///
  /// In pt, this message translates to:
  /// **'Género'**
  String get onboardingGender;

  /// Onboarding body page title
  ///
  /// In pt, this message translates to:
  /// **'Dados corporais'**
  String get onboardingBodyTitle;

  /// Onboarding body page subtitle
  ///
  /// In pt, this message translates to:
  /// **'Usamos estes dados para calcular o teu metabolismo basal e meta calórica diária.'**
  String get onboardingBodySubtitle;

  /// Onboarding birth date placeholder
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data de nascimento'**
  String get onboardingSelectDate;

  /// Onboarding activity page title
  ///
  /// In pt, this message translates to:
  /// **'Nível de atividade'**
  String get onboardingActivityTitle;

  /// Onboarding activity page subtitle
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o nível que melhor descreve a tua rotina semanal atual.'**
  String get onboardingActivitySubtitle;

  /// Onboarding theme page title
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o teu tema'**
  String get onboardingThemeTitle;

  /// Onboarding theme page subtitle
  ///
  /// In pt, this message translates to:
  /// **'Podes sempre mudar isto mais tarde nas definições.'**
  String get onboardingThemeSubtitle;

  /// Button/title to copy a single meal group
  ///
  /// In pt, this message translates to:
  /// **'Copiar Refeição'**
  String get copyMeal;

  /// Prompt to select target meal type when copying
  ///
  /// In pt, this message translates to:
  /// **'Para que refeição?'**
  String get chooseMealType;

  /// Start workout button
  ///
  /// In pt, this message translates to:
  /// **'INICIAR'**
  String get startWorkout;

  /// Bottom sheet title for day selection
  ///
  /// In pt, this message translates to:
  /// **'Escolhe o Dia de Treino'**
  String get chooseTrainingDay;

  /// Bottom sheet subtitle for day selection
  ///
  /// In pt, this message translates to:
  /// **'Seleciona o treino que vais fazer hoje'**
  String get chooseTrainingDaySub;

  /// Exercise progress counter
  ///
  /// In pt, this message translates to:
  /// **'{current} / {total}'**
  String activeWorkoutOf(Object current, Object total);

  /// Planned label in active workout
  ///
  /// In pt, this message translates to:
  /// **'Planeado'**
  String get planned;

  /// Last session label
  ///
  /// In pt, this message translates to:
  /// **'Última sessão'**
  String get lastSession;

  /// No history placeholder
  ///
  /// In pt, this message translates to:
  /// **'Sem histórico ainda'**
  String get noHistoryYet;

  /// Log set button
  ///
  /// In pt, this message translates to:
  /// **'REGISTAR SÉRIE'**
  String get logSet;

  /// Rest timer label
  ///
  /// In pt, this message translates to:
  /// **'Descanso'**
  String get restLabel;

  /// Skip rest button
  ///
  /// In pt, this message translates to:
  /// **'SALTAR'**
  String get skipRest;

  /// Next exercise button
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get nextExercise;

  /// Previous exercise button
  ///
  /// In pt, this message translates to:
  /// **'Anterior'**
  String get prevExercise;

  /// Finish workout button
  ///
  /// In pt, this message translates to:
  /// **'TERMINAR'**
  String get finishWorkout;

  /// Confirm finish dialog title
  ///
  /// In pt, this message translates to:
  /// **'Terminar Treino?'**
  String get confirmFinishTitle;

  /// Confirm finish dialog message
  ///
  /// In pt, this message translates to:
  /// **'As tuas séries já foram guardadas em tempo real. Podes sair sem perder nada.'**
  String get confirmFinishMsg;

  /// Session summary title
  ///
  /// In pt, this message translates to:
  /// **'Treino Concluído! 💪'**
  String get sessionDoneTitle;

  /// Total sets label
  ///
  /// In pt, this message translates to:
  /// **'Séries totais'**
  String get sessionTotalSets;

  /// Total volume label
  ///
  /// In pt, this message translates to:
  /// **'Volume total'**
  String get sessionTotalVolume;

  /// Session duration label
  ///
  /// In pt, this message translates to:
  /// **'Duração'**
  String get sessionDuration;

  /// Close session summary
  ///
  /// In pt, this message translates to:
  /// **'FECHAR'**
  String get sessionClose;

  /// PR celebration title
  ///
  /// In pt, this message translates to:
  /// **'Novo Recorde! 🏆'**
  String get newPR;

  /// Sets logged this session label
  ///
  /// In pt, this message translates to:
  /// **'ESTA SESSÃO'**
  String get setsThisSession;

  /// Validation error for set input
  ///
  /// In pt, this message translates to:
  /// **'Insere carga e repetições válidas!'**
  String get invalidSetInput;

  /// Rest duration adjustment label
  ///
  /// In pt, this message translates to:
  /// **'Ajustar descanso'**
  String get restAdjust;

  /// Yesterday label for workout history dates
  ///
  /// In pt, this message translates to:
  /// **'ontem'**
  String get yesterday;

  /// N days ago label for workout history dates
  ///
  /// In pt, this message translates to:
  /// **'há {n}d'**
  String daysAgo(int n);

  /// Exercise picker screen title
  ///
  /// In pt, this message translates to:
  /// **'Biblioteca de Exercícios'**
  String get exerciseLibraryTitle;

  /// Search bar hint in exercise picker
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar exercícios...'**
  String get exerciseSearchHint;

  /// All categories filter chip
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get allFilter;

  /// Custom exercise tile subtitle
  ///
  /// In pt, this message translates to:
  /// **'Criar exercício personalizado'**
  String get createCustomExercise;

  /// Workout templates picker title
  ///
  /// In pt, this message translates to:
  /// **'Templates de Treino'**
  String get workoutTemplatesTitle;

  /// Workout templates picker subtitle
  ///
  /// In pt, this message translates to:
  /// **'Planos prontos a usar'**
  String get workoutTemplatesSub;

  /// Use template button
  ///
  /// In pt, this message translates to:
  /// **'USAR ESTE TEMPLATE'**
  String get useThisTemplate;

  /// Settings personalization section header
  ///
  /// In pt, this message translates to:
  /// **'Personalização'**
  String get settingsPersonalization;

  /// Meals settings tile subtitle
  ///
  /// In pt, this message translates to:
  /// **'Editar, adicionar e reordenar refeições'**
  String get settingsMealsSub;

  /// Version label with version number
  ///
  /// In pt, this message translates to:
  /// **'Versão {v}'**
  String settingsVersionLabel(String v);

  /// Network error message
  ///
  /// In pt, this message translates to:
  /// **'Falha de rede. Verifica a internet.'**
  String get errorNetwork;

  /// Rate limit error message
  ///
  /// In pt, this message translates to:
  /// **'Muitas pesquisas seguidas. Aguarda 1 minuto.'**
  String get errorRateLimit;

  /// Server down error message
  ///
  /// In pt, this message translates to:
  /// **'A base de dados global está em manutenção.'**
  String get errorServerDown;

  /// Server slow error message
  ///
  /// In pt, this message translates to:
  /// **'Os servidores estão muito lentos. Tenta novamente.'**
  String get errorServerSlow;

  /// Reset meals to default button
  ///
  /// In pt, this message translates to:
  /// **'Repor padrão'**
  String get mealSettingsReset;

  /// Add meal FAB label
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get mealSettingsAdd;

  /// Meals settings info banner
  ///
  /// In pt, this message translates to:
  /// **'Arrasta para reordenar. Os registos passados não são afetados ao editar ou apagar.'**
  String get mealSettingsInfo;

  /// New meal dialog title
  ///
  /// In pt, this message translates to:
  /// **'Nova refeição'**
  String get mealNew;

  /// Edit meal dialog title
  ///
  /// In pt, this message translates to:
  /// **'Editar refeição'**
  String get mealEditTitle;

  /// Delete meal dialog title
  ///
  /// In pt, this message translates to:
  /// **'Apagar refeição?'**
  String get mealDeleteTitle;

  /// Delete meal dialog message
  ///
  /// In pt, this message translates to:
  /// **'A refeição \"{name}\" será removida da lista.\n\nOs registos passados não serão afetados.'**
  String mealDeleteMsg(String name);

  /// Reset meal list dialog title
  ///
  /// In pt, this message translates to:
  /// **'Repor lista original?'**
  String get mealResetTitle;

  /// Reset meal list dialog message
  ///
  /// In pt, this message translates to:
  /// **'A lista será reposta para os valores padrão.\n\nOs registos passados não serão afetados.'**
  String get mealResetMsg;

  /// Restore/reset confirm button
  ///
  /// In pt, this message translates to:
  /// **'Repor'**
  String get mealRestoreAction;

  /// Meal name input hint
  ///
  /// In pt, this message translates to:
  /// **'Ex: Pequeno-Almoço'**
  String get mealNameHint;

  /// Save button (sentence case)
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get saveAction;

  /// Edit icon tooltip
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get editTooltip;

  /// Delete icon tooltip
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get deleteTooltip;

  /// Nutrition detail screen title
  ///
  /// In pt, this message translates to:
  /// **'Resumo Nutricional'**
  String get nutritionSummary;

  /// By meal section header in nutrition detail
  ///
  /// In pt, this message translates to:
  /// **'Por Refeição'**
  String get byMeal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
