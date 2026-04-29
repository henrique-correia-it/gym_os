// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get meals => 'Meals';

  @override
  String get tools => 'Tools';

  @override
  String get utilities => 'Utilities';

  @override
  String get weight => 'Weight';

  @override
  String get history => 'See history';

  @override
  String get imc => 'BMI';

  @override
  String get addFood => 'Add Food';

  @override
  String get viewDiary => 'View Diary';

  @override
  String get readOnly => 'Read Only';

  @override
  String get toolsWeightHistory => 'Weight History';

  @override
  String get toolsWeightHistorySub => 'Track your body evolution';

  @override
  String get toolsBatchCalc => 'Batch Cooking Calc';

  @override
  String get toolsBatchCalcSub => 'Calculate cooked food macros';

  @override
  String get toolsCereal => 'Cereal Calculator';

  @override
  String get toolsCerealSub => 'Perfect mix of Cereal and Liquids';

  @override
  String get toolsWorkout => 'Workout Plan';

  @override
  String get toolsWorkoutSub => 'Manage routines and export to PDF';

  @override
  String get navHome => 'Home';

  @override
  String get navDiet => 'Diet';

  @override
  String get navWorkout => 'Workout';

  @override
  String get navTools => 'Tools';

  @override
  String get navProfile => 'Profile';

  @override
  String get error => 'Error';

  @override
  String get cancel => 'CANCEL';

  @override
  String get save => 'SAVE';

  @override
  String get delete => 'DELETE';

  @override
  String get confirm => 'CONFIRM';

  @override
  String get required => 'Required';

  @override
  String get remaining => 'remaining';

  @override
  String get exceeded => 'exceeded';

  @override
  String get goal => 'Goal';

  @override
  String get consumed => 'Consumed';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get proteinShort => 'P';

  @override
  String get carbsShort => 'C';

  @override
  String get fatShort => 'F';

  @override
  String get noMealsRegistered => 'No meals registered';

  @override
  String get deleteMealTitle => 'Delete Meal?';

  @override
  String deleteMealMessage(Object name) {
    return 'You\'ll remove \'$name\' from this day.';
  }

  @override
  String get mealRemoved => 'Meal removed';

  @override
  String get errorRemoving => 'Error removing';

  @override
  String edit(Object name) {
    return 'Edit $name';
  }

  @override
  String quantity(Object unit) {
    return 'Quantity ($unit)';
  }

  @override
  String get updated => 'Updated!';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealSnack => 'Snack';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealOthers => 'Others';

  @override
  String get searchPlaceholder => 'What are you eating today?';

  @override
  String get searchEmptyTitle =>
      'Search for foods online or\nin your database.';

  @override
  String createFood(Object name) {
    return 'Create \'$name\'';
  }

  @override
  String get onlineLabel => 'Online';

  @override
  String get myFoodsLabel => 'My Foods';

  @override
  String get importAndEdit => 'IMPORT & EDIT';

  @override
  String get editAction => 'EDIT';

  @override
  String get addToDiary => 'ADD TO DIARY';

  @override
  String foodAdded(Object name) {
    return '$name added!';
  }

  @override
  String foodDeleted(Object name) {
    return '$name deleted.';
  }

  @override
  String get imported => 'Imported! Opening editor...';

  @override
  String get errorConnection => 'Connection error: Check your internet.';

  @override
  String get diary => 'Diary';

  @override
  String get feeding => 'Nutrition';

  @override
  String get createFoodTitle => 'Create Food';

  @override
  String get editFoodTitle => 'Edit Food';

  @override
  String get foodName => 'Food Name';

  @override
  String get unit100g => '100g';

  @override
  String get unit1Unit => '1 Unit';

  @override
  String get macrosHint => 'Macros (You can use commas)';

  @override
  String get kcal => 'Kcal';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get createFoodAction => 'CREATE FOOD';

  @override
  String get duplicateFoodTitle => 'Duplicate Food';

  @override
  String duplicateFoodMessage(Object name) {
    return 'A food named \'$name\' already exists.\nDo you want to replace the old values with the new ones?';
  }

  @override
  String get replace => 'REPLACE';

  @override
  String get foodSaved => 'Food saved!';

  @override
  String get configuration => 'Configuration';

  @override
  String get profileAndGoals => 'Profile & Goals';

  @override
  String get dailyGoal => 'DAILY GOAL';

  @override
  String get bmr => 'Basal (BMR)';

  @override
  String get tdee => 'Total Expenditure (TDEE)';

  @override
  String get fieldName => 'Name (Nickname)';

  @override
  String get fieldHeight => 'Height (cm)';

  @override
  String get currentWeight => 'Current Weight (kg)';

  @override
  String get birthDate => 'Birth Date';

  @override
  String get birthDateRequired => 'Birth date required!';

  @override
  String years(Object count) {
    return '$count years';
  }

  @override
  String get activityLevel => 'Activity Level';

  @override
  String get activitySedentary => 'Sedentary';

  @override
  String get activityLight => 'Light (1-3x/week)';

  @override
  String get activityModerate => 'Moderate (3-5x/week)';

  @override
  String get activityIntense => 'Intense (6-7x/week)';

  @override
  String get activityAthlete => 'Athlete (Twice daily)';

  @override
  String get caloricAdjustment => 'Caloric Adjustment';

  @override
  String get adjustmentHint => 'Ex: -300 (Cut), +200 (Bulk)';

  @override
  String get macroSettings => 'Macronutrient Goals';

  @override
  String get macroSettingsHint => 'Adjust % of Prot / Carb / Fat';

  @override
  String get saveProfile => 'SAVE PROFILE';

  @override
  String get profileSaved => 'Profile saved and goal updated!';

  @override
  String get imcUnderweight => 'Underweight';

  @override
  String get imcNormal => 'Normal';

  @override
  String get imcOverweight => 'Overweight';

  @override
  String get imcObese => 'Obese';

  @override
  String get defaultUserNameAthlete => 'Athlete';

  @override
  String get defaultUserName => 'User';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get macroDistribution => 'Macro Distribution';

  @override
  String get totalDistribution => 'Total Distribution';

  @override
  String get mustBe100 => 'Sum must be exactly 100%';

  @override
  String get saveSettings => 'SAVE SETTINGS';

  @override
  String get goalsUpdated => 'Goals updated!';

  @override
  String get preferences => 'Preferences';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Language / Idioma';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAmoled => 'Black';

  @override
  String get dataBackup => 'Data & Backup';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataSub => 'Save backup to file';

  @override
  String get importData => 'Import Data';

  @override
  String get importDataSub => 'Restore backup (Deletes current)';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get importWarningTitle => 'Warning!';

  @override
  String get importWarningMessage =>
      'This will DELETE all current data and replace it with the backup.\nAre you sure?';

  @override
  String get yesRestore => 'Yes, Restore';

  @override
  String get dataRestored => 'Data restored!\nRestarting...';

  @override
  String get corruptFile => 'The file is corrupt or invalid.';

  @override
  String get toolsBatchManager => 'Adjust Batches';

  @override
  String get toolsBatchManagerSub =>
      'Edit ingredients of already created batches';

  @override
  String get toolsOneRepMax => '1RM Calculation (Strength)';

  @override
  String get toolsOneRepMaxSub => 'Estimate your max load and percentages';

  @override
  String get toolsLoadTracker => 'Load Progression';

  @override
  String get toolsLoadTrackerSub =>
      'Monitor your strength increase by exercise';

  @override
  String get toolsRealWeight => 'Real Weight Calculator';

  @override
  String get toolsRealWeightSub =>
      'Calibrate scale weight based on real weight';

  @override
  String get newRecord => 'New Record';

  @override
  String get confirmWeight => 'CONFIRM WEIGHT';

  @override
  String get evolution => 'Evolution';

  @override
  String get weightAnalysis => 'Weight Analysis';

  @override
  String get register => 'REGISTER';

  @override
  String get noWeightRecords => 'No weight records.';

  @override
  String get recentHistory => 'RECENT HISTORY';

  @override
  String get myWorkouts => 'My Workouts';

  @override
  String get newWorkout => 'NEW WORKOUT';

  @override
  String get createFirstRoutine => 'Create your first workout routine';

  @override
  String get workoutEmptyTitle => 'Ready to start training?';

  @override
  String get workoutEmptySubtitle =>
      'Create your first custom plan or get started quickly with one of our templates.';

  @override
  String get workoutEmptyCreateOwn => 'Create from scratch';

  @override
  String get workoutEmptyUseTemplate => 'Use a template';

  @override
  String get tapToEdit => 'Tap to edit or export PDF';

  @override
  String get deletePlanTitle => 'Delete Plan';

  @override
  String deletePlanMessage(Object name) {
    return 'Do you really want to delete \'$name\'?';
  }

  @override
  String get renameSession => 'Rename Session';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get add => 'ADD';

  @override
  String get session => 'SESSION';

  @override
  String get noExercises => 'No exercises';

  @override
  String get addFirst => 'Add First';

  @override
  String get addExerciseAction => 'ADD EXERCISE';

  @override
  String get loads => 'Loads';

  @override
  String get selectExercise => 'Select exercise';

  @override
  String get newSet => 'NEW SET';

  @override
  String get recordProgress => 'RECORD PROGRESS';

  @override
  String get loadEvolution => 'LOAD EVOLUTION';

  @override
  String get realWeight => 'Real Weight';

  @override
  String get oneRepMaxCalc => '1RM Calculation';

  @override
  String get testPerformed => 'PERFORMED TEST';

  @override
  String get intensity => 'Intensity';

  @override
  String get loadAndReps => 'Load & Reps';

  @override
  String get finalAdjustment => 'Final Adjustment & Confirm';

  @override
  String get batchCalcTitle => 'Calculator';

  @override
  String get batchCalcAdjust => 'Adjust';

  @override
  String get batchCalcMarmita => 'Batch';

  @override
  String get batchCalcNameHint => 'Recipe Name';

  @override
  String get batchCalcYield => 'YIELDS';

  @override
  String get batchCalcDoses => 'SERVINGS';

  @override
  String get batchCalcPerDose => 'PER SERVING';

  @override
  String get batchCalcIngredients => 'Ingredients';

  @override
  String batchCalcItems(Object count) {
    return '$count items';
  }

  @override
  String get batchCalcAdd => 'ADD';

  @override
  String get batchCalcSaveAdjustments => 'SAVE ADJUSTMENTS';

  @override
  String get batchCalcSearchIngredient => 'Search Ingredient';

  @override
  String batchCalcEditIngredient(Object name) {
    return 'Edit $name';
  }

  @override
  String get batchCalcNoIngredients => 'Add ingredients first!';

  @override
  String get batchCalcNameRequired => 'Name your batch!';

  @override
  String get batchCalcDosesError => 'Servings must be greater than 0!';

  @override
  String get cerealCalcCalorieGoal => 'CALORIE GOAL';

  @override
  String get cerealCalcCereal => 'Cereal';

  @override
  String get cerealCalcLiquid => 'Liquid';

  @override
  String get cerealCalcWater => 'Water';

  @override
  String get cerealCalcSelect => 'Select';

  @override
  String get cerealCalcAdjustVolume => 'Adjust Liquid Volume?';

  @override
  String get cerealCalcAdjustVolumeSub => 'Sets total bowl quantity';

  @override
  String get cerealCalcTotalVolume => 'Total Volume';

  @override
  String get cerealCalcCalculatedRecipe => 'CALCULATED RECIPE';

  @override
  String cerealCalcEstimate(Object kcal) {
    return 'Estimate: $kcal kcal';
  }

  @override
  String get cerealCalcConfigureFirst => 'Configure recipe first!';

  @override
  String get cerealCalcAddAsDose => 'ADD AS 1 SERVING';

  @override
  String get cerealCalcAdded => 'Recipe added (1 unit)!';

  @override
  String get cerealCalcChooseLiquid => 'Choose Liquid';

  @override
  String get cerealCalcChooseCereal => 'Choose Cereal';

  @override
  String get exerciseName => 'Exercise Name';

  @override
  String get sets => 'Sets';

  @override
  String get reps => 'Reps';

  @override
  String get restSeconds => 'Rest (s)';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get notes => 'Notes';

  @override
  String get addSet => 'Add Set';

  @override
  String yearsOld(Object age) {
    return '$age years';
  }

  @override
  String get birthDateLabel => 'Date of Birth';

  @override
  String get currentWeightLabel => 'Current Weight (kg)';

  @override
  String get macroSettingsTitle => 'Macronutrient Goals';

  @override
  String get macroSettingsSubtitle => 'Adjust Protein / Carbs / Fat %';

  @override
  String duplicateFoodMsg(Object name) {
    return 'A record named \'$name\' already exists. Do you want to replace the old values with the new ones?';
  }

  @override
  String get sourceMarmita => 'Batch Calc';

  @override
  String get ingredientType => 'Ingredient';

  @override
  String get others => 'Others';

  @override
  String get unitKcal => 'kcal';

  @override
  String get unitG => 'g';

  @override
  String get unitUn => 'units';

  @override
  String get weightHistoryTitle => 'Weight History';

  @override
  String get weightHistoryNoData => 'Not enough data for the chart.';

  @override
  String get batchManagerTitle => 'Batch Manager';

  @override
  String get batchManagerIngredients => 'Ingredients';

  @override
  String get loadTrackerTitle => 'Load Tracker';

  @override
  String get loadTrackerExercise => 'Exercise';

  @override
  String get loadTrackerWeight => 'Load (kg)';

  @override
  String get loadTrackerReps => 'Reps';

  @override
  String get loadTrackerChart => 'Progress Chart';

  @override
  String get oneRmTitle => '1RM Calculator';

  @override
  String get oneRmCalculate => 'CALCULATE 1RM';

  @override
  String get oneRmResult => 'Your Estimated 1RM';

  @override
  String get oneRmInstructions =>
      'Enter a weight and how many reps you can perform with it.';

  @override
  String get realWeightTitle => 'Real vs Scale Weight';

  @override
  String get realWeightExplanation =>
      'Use this to calibrate the difference between fasting weight and day weight.';

  @override
  String get realWeightScale => 'Scale Weight';

  @override
  String get realWeightTrue => 'Estimated Real Weight';

  @override
  String get dietTitle => 'Diet';

  @override
  String get dietNutrition => 'Nutrition';

  @override
  String get mealPreWorkout => 'Pre-Workout';

  @override
  String get mealPostWorkout => 'Post-Workout';

  @override
  String get workoutNewPlan => 'New Plan';

  @override
  String get workoutSessionDefault => 'Session';

  @override
  String get workoutRename => 'Rename Plan';

  @override
  String get workoutNameHint => 'Name (e.g., Push, Legs)';

  @override
  String get workoutAddExerciseTitle => 'Add Exercise';

  @override
  String get workoutExerciseName => 'Exercise Name';

  @override
  String get workoutPdfFooter => 'Generated by GymOS • Stay strong!';

  @override
  String get workoutSaveSuccess => 'Plan saved successfully!';

  @override
  String get workoutSaveError => 'Error saving';

  @override
  String get workoutPlanNameHint => 'Plan Name';

  @override
  String get workoutExportPdf => 'Export PDF';

  @override
  String get workoutNewSession => 'New Session';

  @override
  String get workoutDeleteSession => 'Delete Session';

  @override
  String get workoutAddFirst => 'Add First';

  @override
  String get workoutMinDays => 'Plan must have at least 1 day.';

  @override
  String get workoutNameRequired => 'Name your plan!';

  @override
  String get rwCalibration => '1. CALIBRATION (SCALE VS REAL)';

  @override
  String get rwRealWeightShop => 'Real Weight (Butcher)';

  @override
  String get rwScaleWeight => 'On Your Scale';

  @override
  String get rwGoal => '2. YOUR GOAL';

  @override
  String get rwGoalWeight => 'Real Weight you want at end';

  @override
  String get rwInstructions => 'WEIGHING INSTRUCTIONS';

  @override
  String get rwScaleTarget => 'For when the scale shows';

  @override
  String get rwScaleRemove => 'Total to remove on scale';

  @override
  String get rwVerification => '3. FINAL CHECK';

  @override
  String get rwScaleRemovedActual => 'How much did you remove?';

  @override
  String get rwResultReal => 'ACTUAL REAL RESULT';

  @override
  String get rwFinalWeight => 'Real weight left on plate';

  @override
  String get rwRemovedReal => 'Real weight removed';

  @override
  String get ormPureStrength => 'Pure Strength';

  @override
  String get ormHypertrophy => 'Hypertrophy';

  @override
  String get ormEndurance => 'Endurance';

  @override
  String get ormExplosion => 'Cardio/Explosion';

  @override
  String get ormFillData => 'Fill in the data above\nto generate the table.';

  @override
  String get backupShareText => 'GymOS Backup';

  @override
  String get setSaved => 'Set recorded!';

  @override
  String get recordDeleted => 'Record deleted';

  @override
  String get startBySelecting =>
      'Start by selecting an exercise\nto see your progress.';

  @override
  String get batchEmpty => 'No batches found';

  @override
  String get batchDeleteTitle => 'Delete Batch';

  @override
  String batchDeleteConfirm(Object name) {
    return 'Are you sure you want to delete the \'$name\' recipe?';
  }

  @override
  String get cerealCalcEditIngredients => 'Ingredients (Edit)';

  @override
  String get mealSupper => 'Supper';

  @override
  String get copyMealsToTomorrow => 'Copy meals to tomorrow';

  @override
  String get clearDay => 'Clear day';

  @override
  String get clearDayTitle => 'Clear day?';

  @override
  String get clearDayMessage =>
      'This will delete all meals for this day. This action cannot be undone.';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get dayClearedSuccess => 'Day cleared successfully!';

  @override
  String errorClearingDay(Object error) {
    return 'Error clearing day: $error';
  }

  @override
  String get tomorrowHasRecords => 'Tomorrow already has records';

  @override
  String get tomorrowHasRecordsMessage =>
      'Tomorrow already contains meals. Do you want to append today\'s meals to the existing list?';

  @override
  String get mealsCopiedSuccess =>
      'Today\'s meals successfully copied to tomorrow!';

  @override
  String errorCopying(Object error) {
    return 'Error copying: $error';
  }

  @override
  String get selectMealError => 'Please select a meal';

  @override
  String exportError(Object error) {
    return 'Error exporting: $error';
  }

  @override
  String openFileError(Object error) {
    return 'Error opening file: $error';
  }

  @override
  String get searchWord => 'Search...';

  @override
  String get maxStrength => 'MAX STRENGTH';

  @override
  String get liquidAdjustMode => 'Liquid Adjust Mode';

  @override
  String porridgeOf(Object name) {
    return '$name Porridge';
  }

  @override
  String get workoutDeleted => 'Workout removed';

  @override
  String criticalDbError(Object error) {
    return 'CRITICAL ERROR STARTING DB: $error';
  }

  @override
  String get myFavorites => 'My Favorites';

  @override
  String importDataError(Object error) {
    return 'Error importing data: $error';
  }

  @override
  String get backupRestoredSuccess => 'Backup restored successfully!';

  @override
  String fatalRestoreError(Object error) {
    return 'Fatal error restoring backup: $error';
  }

  @override
  String get versionAlpha => 'v1.0.0 Alpha';

  @override
  String get madeWithLove => 'Made with ❤️ for you';

  @override
  String get batchCalcShort => 'Batch Calc';

  @override
  String serverError(Object code) {
    return 'Server error: $code';
  }

  @override
  String apiError(Object error) {
    return 'GymOS API Error: $error';
  }

  @override
  String get breakfastShort => 'Breakfast';

  @override
  String get loginStatusPreparing => 'Preparing your gym...';

  @override
  String get loginStatusConnecting => 'Connecting to Google...';

  @override
  String get loginErrorCancelled => 'Session cancelled or failed.';

  @override
  String get loginStatusDownloading => 'Downloading your progress...';

  @override
  String get loginStatusCreatingProfile => 'Creating your GymOS profile...';

  @override
  String get loginErrorSync =>
      'Sync error. Check your connection and try again.';

  @override
  String get loginSubtitle => 'THE ULTIMATE FITNESS OS';

  @override
  String get loginContinueWithGoogle => 'CONTINUE WITH GOOGLE';

  @override
  String get copyMealsTo => 'Copy Meals';

  @override
  String get chooseDestinationDay =>
      'Choose the destination day for the records.';

  @override
  String get forToday => 'For Today';

  @override
  String get forTomorrow => 'For Tomorrow';

  @override
  String targetHasRecordsMessage(Object targetName) {
    return '$targetName already contains meals. Do you want to add the new meals to the existing ones?';
  }

  @override
  String recordsInTarget(Object targetName) {
    return 'Records on $targetName';
  }

  @override
  String mealsCopiedTargetSuccess(Object targetName) {
    return 'Meals successfully copied to $targetName!';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get macroSmartPresetsTitle => 'QUICK STRATEGIES (SMART PRESETS)';

  @override
  String get macroDistributionSection => 'MACRONUTRIENT DISTRIBUTION';

  @override
  String macroCalculationBase(Object kcal) {
    return 'Calculated based on your daily goal of $kcal kcal.';
  }

  @override
  String get macroStatusPerfect => 'PERFECT DISTRIBUTION';

  @override
  String macroStatusExcess(Object percent) {
    return 'EXCESS OF $percent%';
  }

  @override
  String macroStatusMissing(Object percent) {
    return 'MISSING $percent%';
  }

  @override
  String get macroPresetBalanced => 'Balanced';

  @override
  String get macroPresetHypertrophy => 'Hypertrophy';

  @override
  String get macroPresetLowCarb => 'Low Carb';

  @override
  String get profileSectionPersonal => 'PERSONAL DATA';

  @override
  String get profileSectionBody => 'BODY & LIFESTYLE';

  @override
  String get profileSectionStrategy => 'NUTRITIONAL STRATEGY';

  @override
  String get profileDone => 'Done';

  @override
  String get profileSelect => 'Select';

  @override
  String get activitySedentaryDesc => 'Little or no exercise';

  @override
  String get activityLightDesc => 'Light exercise 1-3 days/week';

  @override
  String get activityModerateDesc => 'Moderate exercise 3-5 days/week';

  @override
  String get activityIntenseDesc => 'Intense exercise 6-7 days/week';

  @override
  String get activityAthleteDesc => 'Athlete or very heavy physical work';

  @override
  String get settingsBackupInProgress => 'Saving your data to the cloud...';

  @override
  String get settingsBackupSuccess => 'Backup completed successfully!';

  @override
  String settingsBackupError(Object error) {
    return 'Error saving to cloud: $error';
  }

  @override
  String get settingsRestoreWarningMsg =>
      'This will replace your current data with the data saved in your Google account. Do you want to continue?';

  @override
  String get settingsRestoreInProgress =>
      'Restoring your data from the cloud...';

  @override
  String settingsRestoreError(Object error) {
    return 'Error restoring: $error';
  }

  @override
  String get settingsLogoutTitle => 'Logout';

  @override
  String get settingsLogoutMessage =>
      'Are you sure you want to log out? This will remove your local data from this device (your cloud data is safe).';

  @override
  String settingsLogoutError(Object error) {
    return 'Error logging out: $error';
  }

  @override
  String get settingsAutoSyncTitle => 'Auto Sync';

  @override
  String get settingsAutoSyncSubtitle =>
      'Save changes to the cloud automatically';

  @override
  String get settingsBackupDataTitle => 'Backup Data';

  @override
  String get settingsBackupDataSubtitle => 'Force data sync with Google';

  @override
  String get settingsRestoreDataTitle => 'Restore Data from Cloud';

  @override
  String get settingsRestoreDataSubtitle => 'Recover previously saved data';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsLogoutItemTitle => 'Logout';

  @override
  String get settingsLogoutItemSubtitle =>
      'Sign out of your account and clear local data';

  @override
  String get settingsLanguageMain => 'Main Version';

  @override
  String get settingsLanguageDev => 'In development';

  @override
  String get settingsLanguageDevWarning =>
      'Warning: Language still in development. Some translations will be missing.';

  @override
  String get unknown => 'Unknown';

  @override
  String get duplicateWeightTitle => 'Weight already recorded';

  @override
  String duplicateWeightMessage(String weight) {
    return 'You already recorded $weight kg for this day. Do you want to replace it with the new value?';
  }

  @override
  String get deleteWeightTitle => 'Delete record?';

  @override
  String deleteWeightMessage(String date) {
    return 'Are you sure you want to delete the record from $date?';
  }

  @override
  String get generalCategory => 'General';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingNext => 'Continue';

  @override
  String get onboardingFinish => 'Enter App';

  @override
  String get onboardingWelcomeTitle => 'Welcome\nto GymOS.';

  @override
  String get onboardingWelcomeSubtitle =>
      'Your workout and nutrition companion. Let\'s set everything up in under 2 minutes.';

  @override
  String get onboardingFeature1 => 'Log your daily meals';

  @override
  String get onboardingFeature2 => 'Track your weight and progress';

  @override
  String get onboardingFeature3 => 'Manage your workout plans';

  @override
  String get onboardingNameTitle => 'What\'s your name?';

  @override
  String get onboardingNameSubtitle =>
      'Tell us your name and gender so we can personalize your experience.';

  @override
  String get onboardingNameHint => 'Your name or nickname';

  @override
  String get onboardingGender => 'Gender';

  @override
  String get onboardingBodyTitle => 'Body data';

  @override
  String get onboardingBodySubtitle =>
      'We use this data to calculate your basal metabolism and daily calorie goal.';

  @override
  String get onboardingSelectDate => 'Select birth date';

  @override
  String get onboardingActivityTitle => 'Activity level';

  @override
  String get onboardingActivitySubtitle =>
      'Choose the level that best describes your current weekly routine.';

  @override
  String get onboardingThemeTitle => 'Choose your theme';

  @override
  String get onboardingThemeSubtitle =>
      'You can always change this later in settings.';

  @override
  String get copyMeal => 'Copy Meal';

  @override
  String get chooseMealType => 'Target meal?';

  @override
  String get startWorkout => 'START';

  @override
  String get chooseTrainingDay => 'Choose Training Day';

  @override
  String get chooseTrainingDaySub => 'Select which workout you\'ll do today';

  @override
  String activeWorkoutOf(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get planned => 'Planned';

  @override
  String get lastSession => 'Last session';

  @override
  String get noHistoryYet => 'No history yet';

  @override
  String get logSet => 'LOG SET';

  @override
  String get restLabel => 'Rest';

  @override
  String get skipRest => 'SKIP';

  @override
  String get nextExercise => 'Next';

  @override
  String get prevExercise => 'Previous';

  @override
  String get finishWorkout => 'FINISH';

  @override
  String get confirmFinishTitle => 'Finish Workout?';

  @override
  String get confirmFinishMsg =>
      'Your sets were saved in real time. You can leave without losing anything.';

  @override
  String get sessionDoneTitle => 'Workout Done! 💪';

  @override
  String get sessionTotalSets => 'Total sets';

  @override
  String get sessionTotalVolume => 'Total volume';

  @override
  String get sessionDuration => 'Duration';

  @override
  String get sessionClose => 'CLOSE';

  @override
  String get newPR => 'New Record! 🏆';

  @override
  String get setsThisSession => 'THIS SESSION';

  @override
  String get invalidSetInput => 'Enter valid weight and reps!';

  @override
  String get restAdjust => 'Adjust rest';

  @override
  String get yesterday => 'yesterday';

  @override
  String daysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get exerciseLibraryTitle => 'Exercise Library';

  @override
  String get exerciseSearchHint => 'Search exercises...';

  @override
  String get allFilter => 'All';

  @override
  String get createCustomExercise => 'Create custom exercise';

  @override
  String get workoutTemplatesTitle => 'Workout Templates';

  @override
  String get workoutTemplatesSub => 'Ready-to-use plans';

  @override
  String get useThisTemplate => 'USE THIS TEMPLATE';

  @override
  String get settingsPersonalization => 'Personalization';

  @override
  String get settingsMealsSub => 'Edit, add and reorder meals';

  @override
  String settingsVersionLabel(String v) {
    return 'Version $v';
  }

  @override
  String get errorNetwork => 'Network failure. Check your internet.';

  @override
  String get errorRateLimit => 'Too many searches in a row. Wait 1 minute.';

  @override
  String get errorServerDown => 'The global database is under maintenance.';

  @override
  String get errorServerSlow => 'Servers are too slow. Try again.';

  @override
  String get mealSettingsReset => 'Reset to default';

  @override
  String get mealSettingsAdd => 'Add';

  @override
  String get mealSettingsInfo =>
      'Drag to reorder. Past records are not affected when editing or deleting.';

  @override
  String get mealNew => 'New meal';

  @override
  String get mealEditTitle => 'Edit meal';

  @override
  String get mealDeleteTitle => 'Delete meal?';

  @override
  String mealDeleteMsg(String name) {
    return 'The meal \"$name\" will be removed from the list.\n\nPast records will not be affected.';
  }

  @override
  String get mealResetTitle => 'Reset original list?';

  @override
  String get mealResetMsg =>
      'The list will be reset to default values.\n\nPast records will not be affected.';

  @override
  String get mealRestoreAction => 'Reset';

  @override
  String get mealNameHint => 'E.g.: Breakfast';

  @override
  String get saveAction => 'Save';

  @override
  String get editTooltip => 'Edit';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get nutritionSummary => 'Nutrition Summary';

  @override
  String get byMeal => 'By Meal';

  @override
  String get workoutSubtitle => 'Plans & Routines';

  @override
  String get toolsSubtitle => 'Calculators & Records';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get toolsWorkoutHistory => 'Workout History';

  @override
  String get toolsWorkoutHistorySub => 'View all your completed workouts';

  @override
  String get workoutHistoryTitle => 'Workout History';

  @override
  String get workoutHistoryEmpty => 'No workouts recorded';

  @override
  String get workoutHistoryEmptySub =>
      'Start a workout to see your history here.';

  @override
  String get workoutHistoryExercises => 'Exercises';

  @override
  String get workoutHistoryVolume => 'Volume';

  @override
  String get editSet => 'Edit Set';
}
