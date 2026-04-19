// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get meals => 'Comidas';

  @override
  String get tools => 'Herramientas';

  @override
  String get utilities => 'Utilidades';

  @override
  String get weight => 'Peso';

  @override
  String get history => 'Ver historial';

  @override
  String get imc => 'IMC';

  @override
  String get addFood => 'Añadir Alimento';

  @override
  String get viewDiary => 'Ver Diario';

  @override
  String get readOnly => 'Solo Lectura';

  @override
  String get toolsWeightHistory => 'Historial de Peso';

  @override
  String get toolsWeightHistorySub => 'Registra y sigue tu evolución corporal';

  @override
  String get toolsBatchCalc => 'Calculadora de Lotes';

  @override
  String get toolsBatchCalcSub => 'Calcula macros de comida cocinada';

  @override
  String get toolsCereal => 'Calculadora de Papillas';

  @override
  String get toolsCerealSub => 'Mezcla perfecta de Cereales y Líquidos';

  @override
  String get toolsWorkout => 'Plan de Entrenamiento';

  @override
  String get toolsWorkoutSub => 'Gestiona tus rutinas y exporta a PDF';

  @override
  String get navHome => 'Inicio';

  @override
  String get navDiet => 'Dieta';

  @override
  String get navWorkout => 'Entreno';

  @override
  String get navTools => 'Herr.';

  @override
  String get navProfile => 'Perfil';

  @override
  String get error => 'Error';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get save => 'GUARDAR';

  @override
  String get delete => 'BORRAR';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get required => 'Obligatorio';

  @override
  String get remaining => 'restan';

  @override
  String get exceeded => 'excedido';

  @override
  String get goal => 'Meta';

  @override
  String get consumed => 'Consumido';

  @override
  String get protein => 'Proteína';

  @override
  String get carbs => 'Carbohidratos';

  @override
  String get fat => 'Grasas';

  @override
  String get proteinShort => 'P';

  @override
  String get carbsShort => 'C';

  @override
  String get fatShort => 'G';

  @override
  String get noMealsRegistered => 'Sin comidas registradas';

  @override
  String get deleteMealTitle => '¿Borrar Comida?';

  @override
  String deleteMealMessage(Object name) {
    return 'Vas a eliminar \'$name\' de este día.';
  }

  @override
  String get mealRemoved => 'Comida eliminada';

  @override
  String get errorRemoving => 'Error al eliminar';

  @override
  String edit(Object name) {
    return 'Editar $name';
  }

  @override
  String quantity(Object unit) {
    return 'Cantidad ($unit)';
  }

  @override
  String get updated => '¡Actualizado!';

  @override
  String get mealBreakfast => 'Desayuno';

  @override
  String get mealLunch => 'Almuerzo';

  @override
  String get mealSnack => 'Merienda';

  @override
  String get mealDinner => 'Cena';

  @override
  String get mealOthers => 'Otros';

  @override
  String get searchPlaceholder => '¿Qué vas a comer hoy?';

  @override
  String get searchEmptyTitle =>
      'Busca alimentos online o\nen tu base de datos.';

  @override
  String createFood(Object name) {
    return 'Crear \'$name\'';
  }

  @override
  String get onlineLabel => 'Online';

  @override
  String get myFoodsLabel => 'Mis Alimentos';

  @override
  String get importAndEdit => 'IMPORTAR Y EDITAR';

  @override
  String get editAction => 'EDITAR';

  @override
  String get addToDiary => 'AÑADIR AL DIARIO';

  @override
  String foodAdded(Object name) {
    return '¡$name añadido!';
  }

  @override
  String foodDeleted(Object name) {
    return '$name borrado.';
  }

  @override
  String get imported => '¡Importado! Abriendo editor...';

  @override
  String get errorConnection => 'Error de conexión: Verifica tu internet.';

  @override
  String get diary => 'Diario';

  @override
  String get feeding => 'Alimentación';

  @override
  String get createFoodTitle => 'Crear Alimento';

  @override
  String get editFoodTitle => 'Editar Alimento';

  @override
  String get foodName => 'Nombre del Alimento';

  @override
  String get unit100g => '100g';

  @override
  String get unit1Unit => '1 Unidad';

  @override
  String get macrosHint => 'Macros (Puedes usar comas)';

  @override
  String get kcal => 'Kcal';

  @override
  String get saveChanges => 'GUARDAR CAMBIOS';

  @override
  String get createFoodAction => 'CREAR ALIMENTO';

  @override
  String get duplicateFoodTitle => 'Alimento Repetido';

  @override
  String duplicateFoodMessage(Object name) {
    return 'Ya existe un registro llamado \'$name\'.\n¿Deseas reemplazar los valores antiguos por los nuevos?';
  }

  @override
  String get replace => 'REEMPLAZAR';

  @override
  String get foodSaved => '¡Alimento guardado!';

  @override
  String get configuration => 'Configuración';

  @override
  String get profileAndGoals => 'Perfil y Metas';

  @override
  String get dailyGoal => 'META DIARIA';

  @override
  String get bmr => 'Basal (TMB)';

  @override
  String get tdee => 'Gasto Total (TDEE)';

  @override
  String get fieldName => 'Nombre (Apodo)';

  @override
  String get fieldHeight => 'Altura (cm)';

  @override
  String get currentWeight => 'Peso Actual (kg)';

  @override
  String get birthDate => 'Fecha de Nacimiento';

  @override
  String get birthDateRequired => '¡Fecha de nacimiento obligatoria!';

  @override
  String years(Object count) {
    return '$count años';
  }

  @override
  String get activityLevel => 'Nivel de Actividad';

  @override
  String get activitySedentary => 'Sedentario';

  @override
  String get activityLight => 'Ligero (1-3x/sem)';

  @override
  String get activityModerate => 'Moderado (3-5x/sem)';

  @override
  String get activityIntense => 'Intenso (6-7x/sem)';

  @override
  String get activityAthlete => 'Atleta (Doble sesión)';

  @override
  String get caloricAdjustment => 'Ajuste Calórico';

  @override
  String get adjustmentHint => 'Ej: -300 (Déficit), +200 (Volumen)';

  @override
  String get macroSettings => 'Metas de Macronutrientes';

  @override
  String get macroSettingsHint => 'Ajustar % de Prot / Carb / Gras';

  @override
  String get saveProfile => 'GUARDAR PERFIL';

  @override
  String get profileSaved => '¡Perfil guardado y meta actualizada!';

  @override
  String get imcUnderweight => 'Bajo Peso';

  @override
  String get imcNormal => 'Normal';

  @override
  String get imcOverweight => 'Sobrepeso';

  @override
  String get imcObese => 'Obesidad';

  @override
  String get defaultUserNameAthlete => 'Atleta';

  @override
  String get defaultUserName => 'Usuario';

  @override
  String get male => 'Masc.';

  @override
  String get female => 'Fem.';

  @override
  String get macroDistribution => 'División de Macros';

  @override
  String get totalDistribution => 'Total de la Distribución';

  @override
  String get mustBe100 => 'La suma debe ser exactamente 100%';

  @override
  String get saveSettings => 'GUARDAR AJUSTES';

  @override
  String get goalsUpdated => '¡Metas actualizadas!';

  @override
  String get preferences => 'Preferencias';

  @override
  String get settings => 'Ajustes';

  @override
  String get general => 'General';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Language / Idioma';

  @override
  String get appearance => 'Apariencia';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeAmoled => 'Negro';

  @override
  String get dataBackup => 'Datos y Copia de Seguridad';

  @override
  String get exportData => 'Exportar Datos';

  @override
  String get exportDataSub => 'Guardar copia en un archivo';

  @override
  String get importData => 'Importar Datos';

  @override
  String get importDataSub => 'Restaurar copia (Borra actual)';

  @override
  String get about => 'Acerca de';

  @override
  String get version => 'Versión';

  @override
  String get importWarningTitle => '¡Atención!';

  @override
  String get importWarningMessage =>
      'Esto BORRARÁ todos los datos actuales y los reemplazará con la copia.\n¿Estás seguro?';

  @override
  String get yesRestore => 'Sí, Restaurar';

  @override
  String get dataRestored => '¡Datos restaurados!\nReiniciando...';

  @override
  String get corruptFile => 'El archivo está corrupto o es inválido.';

  @override
  String get toolsBatchManager => 'Ajustar Lotes';

  @override
  String get toolsBatchManagerSub =>
      'Edita los ingredientes de lotes ya creados';

  @override
  String get toolsOneRepMax => 'Cálculo 1RM (Fuerza)';

  @override
  String get toolsOneRepMaxSub => 'Estima tu carga máxima y porcentajes';

  @override
  String get toolsLoadTracker => 'Progresión de Cargas';

  @override
  String get toolsLoadTrackerSub =>
      'Monitoriza tu aumento de fuerza por ejercicio';

  @override
  String get toolsRealWeight => 'Calculadora de Peso Real';

  @override
  String get toolsRealWeightSub =>
      'Calibra el peso de tu báscula basado en el peso real';

  @override
  String get newRecord => 'Nuevo Registro';

  @override
  String get confirmWeight => 'CONFIRMAR PESO';

  @override
  String get evolution => 'Evolución';

  @override
  String get weightAnalysis => 'Análisis de Peso';

  @override
  String get register => 'REGISTRAR';

  @override
  String get noWeightRecords => 'Sin registros de peso.';

  @override
  String get recentHistory => 'HISTORIAL RECIENTE';

  @override
  String get myWorkouts => 'Mis Entrenamientos';

  @override
  String get newWorkout => 'NUEVO ENTRENAMIENTO';

  @override
  String get createFirstRoutine => 'Crea tu primera rutina de entrenamiento';

  @override
  String get workoutEmptyTitle => '¿Listo para entrenar?';

  @override
  String get workoutEmptySubtitle =>
      'Crea tu primer plan personalizado o empieza rápido con uno de nuestros templates.';

  @override
  String get workoutEmptyCreateOwn => 'Crear desde cero';

  @override
  String get workoutEmptyUseTemplate => 'Usar un template';

  @override
  String get tapToEdit => 'Toca para editar o exportar PDF';

  @override
  String get deletePlanTitle => 'Borrar Plan';

  @override
  String deletePlanMessage(Object name) {
    return '¿Realmente quieres eliminar \'$name\'?';
  }

  @override
  String get renameSession => 'Renombrar Sesión';

  @override
  String get addExercise => 'Añadir Ejercicio';

  @override
  String get add => 'AÑADIR';

  @override
  String get session => 'SESIÓN';

  @override
  String get noExercises => 'Sin ejercicios';

  @override
  String get addFirst => 'Añadir Primero';

  @override
  String get addExerciseAction => 'AÑADIR EJERCICIO';

  @override
  String get loads => 'Cargas';

  @override
  String get selectExercise => 'Selecciona el ejercicio';

  @override
  String get newSet => 'NUEVA SERIE';

  @override
  String get recordProgress => 'REGISTRAR PROGRESO';

  @override
  String get loadEvolution => 'EVOLUCIÓN DE CARGA';

  @override
  String get realWeight => 'Peso Real';

  @override
  String get oneRepMaxCalc => 'Cálculo 1RM';

  @override
  String get testPerformed => 'TEST REALIZADO';

  @override
  String get intensity => 'Intensidad';

  @override
  String get loadAndReps => 'Carga y Reps';

  @override
  String get finalAdjustment => 'Ajuste Final y Confirmar';

  @override
  String get batchCalcTitle => 'Calculadora';

  @override
  String get batchCalcAdjust => 'Ajustar';

  @override
  String get batchCalcMarmita => 'Lote';

  @override
  String get batchCalcNameHint => 'Nombre de la Receta';

  @override
  String get batchCalcYield => 'RINDE';

  @override
  String get batchCalcDoses => 'DOSIS';

  @override
  String get batchCalcPerDose => 'POR DOSIS';

  @override
  String get batchCalcIngredients => 'Ingredientes';

  @override
  String batchCalcItems(Object count) {
    return '$count ítems';
  }

  @override
  String get batchCalcAdd => 'AÑADIR';

  @override
  String get batchCalcSaveAdjustments => 'GUARDAR AJUSTES';

  @override
  String get batchCalcSearchIngredient => 'Buscar Ingrediente';

  @override
  String batchCalcEditIngredient(Object name) {
    return 'Editar $name';
  }

  @override
  String get batchCalcNoIngredients => '¡Añade ingredientes primero!';

  @override
  String get batchCalcNameRequired => '¡Dale un nombre al lote!';

  @override
  String get batchCalcDosesError => '¡El número de dosis debe ser mayor que 0!';

  @override
  String get cerealCalcCalorieGoal => 'META DE CALORÍAS';

  @override
  String get cerealCalcCereal => 'Cereal';

  @override
  String get cerealCalcLiquid => 'Líquido';

  @override
  String get cerealCalcWater => 'Agua';

  @override
  String get cerealCalcSelect => 'Seleccionar';

  @override
  String get cerealCalcAdjustVolume => '¿Ajustar Volumen Líquido?';

  @override
  String get cerealCalcAdjustVolumeSub => 'Define la cantidad total del bol';

  @override
  String get cerealCalcTotalVolume => 'Volumen Total';

  @override
  String get cerealCalcCalculatedRecipe => 'RECETA CALCULADA';

  @override
  String cerealCalcEstimate(Object kcal) {
    return 'Estimación: $kcal kcal';
  }

  @override
  String get cerealCalcConfigureFirst => '¡Configura la receta primero!';

  @override
  String get cerealCalcAddAsDose => 'AÑADIR COMO 1 DOSIS';

  @override
  String get cerealCalcAdded => '¡Receta añadida (1 un)!';

  @override
  String get cerealCalcChooseLiquid => 'Elegir Líquido';

  @override
  String get cerealCalcChooseCereal => 'Elegir Cereal';

  @override
  String get exerciseName => 'Nombre del Ejercicio';

  @override
  String get sets => 'Series';

  @override
  String get reps => 'Reps';

  @override
  String get restSeconds => 'Descanso (s)';

  @override
  String get weightKg => 'Carga (kg)';

  @override
  String get notes => 'Notas';

  @override
  String get addSet => 'Añadir Serie';

  @override
  String yearsOld(Object age) {
    return '$age años';
  }

  @override
  String get birthDateLabel => 'Fecha de Nacimiento';

  @override
  String get currentWeightLabel => 'Peso Actual (kg)';

  @override
  String get macroSettingsTitle => 'Metas de Macronutrientes';

  @override
  String get macroSettingsSubtitle => 'Ajustar % de Prot / Carb / Gras';

  @override
  String duplicateFoodMsg(Object name) {
    return 'Ya existe un registro llamado \'$name\'. ¿Deseas reemplazar los valores antiguos por los nuevos?';
  }

  @override
  String get sourceMarmita => 'Calc. Lotes';

  @override
  String get ingredientType => 'Ingrediente';

  @override
  String get others => 'Otros';

  @override
  String get unitKcal => 'kcal';

  @override
  String get unitG => 'g';

  @override
  String get unitUn => 'un';

  @override
  String get weightHistoryTitle => 'Historial de Peso';

  @override
  String get weightHistoryNoData => 'Sin datos suficientes para el gráfico.';

  @override
  String get batchManagerTitle => 'Gestionar Lotes';

  @override
  String get batchManagerIngredients => 'Ingredientes';

  @override
  String get loadTrackerTitle => 'Evolución de Cargas';

  @override
  String get loadTrackerExercise => 'Ejercicio';

  @override
  String get loadTrackerWeight => 'Carga (kg)';

  @override
  String get loadTrackerReps => 'Repeticiones';

  @override
  String get loadTrackerChart => 'Gráfico de Evolución';

  @override
  String get oneRmTitle => 'Calculadora 1RM';

  @override
  String get oneRmCalculate => 'CALCULAR 1RM';

  @override
  String get oneRmResult => 'Tu 1RM Estimado';

  @override
  String get oneRmInstructions =>
      'Introduce una carga y cuántas repeticiones puedes hacer con ella.';

  @override
  String get realWeightTitle => 'Peso Real vs Báscula';

  @override
  String get realWeightExplanation =>
      'Usa esto para calibrar la diferencia entre pesajes en ayunas y pesajes durante el día.';

  @override
  String get realWeightScale => 'Peso en Báscula';

  @override
  String get realWeightTrue => 'Peso Real Estimado';

  @override
  String get dietTitle => 'Dieta';

  @override
  String get dietNutrition => 'Nutrición';

  @override
  String get mealPreWorkout => 'Pre-Entreno';

  @override
  String get mealPostWorkout => 'Post-Entreno';

  @override
  String get workoutNewPlan => 'Nuevo Plan';

  @override
  String get workoutSessionDefault => 'Sesión';

  @override
  String get workoutRename => 'Renombrar Sesión';

  @override
  String get workoutNameHint => 'Nombre (ej: Empuje, Pierna)';

  @override
  String get workoutAddExerciseTitle => 'Añadir Ejercicio';

  @override
  String get workoutExerciseName => 'Nombre del Ejercicio';

  @override
  String get workoutPdfFooter => 'Generado por GymOS • ¡Mantente fuerte!';

  @override
  String get workoutSaveSuccess => '¡Plan guardado con éxito!';

  @override
  String get workoutSaveError => 'Error al guardar';

  @override
  String get workoutPlanNameHint => 'Nombre del Plan';

  @override
  String get workoutExportPdf => 'Exportar PDF';

  @override
  String get workoutNewSession => 'Nueva Sesión';

  @override
  String get workoutDeleteSession => 'Borrar Sesión';

  @override
  String get workoutAddFirst => 'Añadir Primero';

  @override
  String get workoutMinDays => 'El plan debe tener al menos 1 día.';

  @override
  String get workoutNameRequired => '¡Ponle nombre al plan!';

  @override
  String get rwCalibration => '1. CALIBRACIÓN (BÁSCULA VS REAL)';

  @override
  String get rwRealWeightShop => 'Peso Real (Referencia)';

  @override
  String get rwScaleWeight => 'En Tu Báscula';

  @override
  String get rwGoal => '2. TU OBJETIVO';

  @override
  String get rwGoalWeight => 'Peso Real deseado al final';

  @override
  String get rwInstructions => 'INSTRUCCIONES DE PESAJES';

  @override
  String get rwScaleTarget => 'Cuando la báscula marque';

  @override
  String get rwScaleRemove => 'Total a restar en báscula';

  @override
  String get rwVerification => '3. VERIFICACIÓN FINAL';

  @override
  String get rwScaleRemovedActual => '¿Cuánto has restado?';

  @override
  String get rwResultReal => 'RESULTADO REAL OBTENIDO';

  @override
  String get rwFinalWeight => 'Peso real final';

  @override
  String get rwRemovedReal => 'Peso real perdido';

  @override
  String get ormPureStrength => 'Fuerza Pura';

  @override
  String get ormHypertrophy => 'Hipertrofia';

  @override
  String get ormEndurance => 'Resistencia';

  @override
  String get ormExplosion => 'Cardio/Explosión';

  @override
  String get ormFillData =>
      'Rellena los datos de arriba\npara generar la tabla.';

  @override
  String get backupShareText => 'Copia de seguridad GymOS';

  @override
  String get setSaved => '¡Serie registrada!';

  @override
  String get recordDeleted => 'Registro borrado';

  @override
  String get startBySelecting =>
      'Empieza seleccionando un ejercicio\npara ver tu progreso.';

  @override
  String get batchEmpty => 'No se encontraron lotes';

  @override
  String get batchDeleteTitle => 'Borrar Lote';

  @override
  String batchDeleteConfirm(Object name) {
    return '¿Estás seguro de que quieres eliminar la receta \'$name\'?';
  }

  @override
  String get cerealCalcEditIngredients => 'Ingredientes (Editar)';

  @override
  String get mealSupper => 'Recena';

  @override
  String get copyMealsToTomorrow => 'Copiar comidas para mañana';

  @override
  String get clearDay => 'Limpiar día';

  @override
  String get clearDayTitle => '¿Limpiar día?';

  @override
  String get clearDayMessage =>
      'Esto borrará todas las comidas de este día. Esta acción no se puede deshacer.';

  @override
  String get deleteAll => 'Borrar Todo';

  @override
  String get dayClearedSuccess => '¡Día limpiado con éxito!';

  @override
  String errorClearingDay(Object error) {
    return 'Error al limpiar día: $error';
  }

  @override
  String get tomorrowHasRecords => 'Mañana ya tiene registros';

  @override
  String get tomorrowHasRecordsMessage =>
      'El día de mañana ya contiene comidas. ¿Deseas añadir las comidas de hoy a la lista existente?';

  @override
  String get mealsCopiedSuccess =>
      '¡Comidas de hoy copiadas para mañana con éxito!';

  @override
  String errorCopying(Object error) {
    return 'Error al copiar: $error';
  }

  @override
  String get selectMealError => 'Por favor selecciona una comida';

  @override
  String exportError(Object error) {
    return 'Error al exportar: $error';
  }

  @override
  String openFileError(Object error) {
    return 'Error al abrir archivo: $error';
  }

  @override
  String get searchWord => 'Buscar...';

  @override
  String get maxStrength => 'FUERZA MÁXIMA';

  @override
  String get liquidAdjustMode => 'Modo Ajuste Líquido';

  @override
  String porridgeOf(Object name) {
    return 'Papilla de $name';
  }

  @override
  String get workoutDeleted => 'Entrenamiento eliminado';

  @override
  String criticalDbError(Object error) {
    return 'ERROR CRÍTICO AL INICIAR BD: $error';
  }

  @override
  String get myFavorites => 'Mis Favoritos';

  @override
  String importDataError(Object error) {
    return 'Error al importar datos: $error';
  }

  @override
  String get backupRestoredSuccess =>
      '¡Copia de seguridad restaurada con éxito!';

  @override
  String fatalRestoreError(Object error) {
    return 'Error fatal al restaurar copia: $error';
  }

  @override
  String get versionAlpha => 'v1.0.0 Alfa';

  @override
  String get madeWithLove => 'Hecho con ❤️ para ti';

  @override
  String get batchCalcShort => 'Calc. Lotes';

  @override
  String serverError(Object code) {
    return 'Error en el servidor: $code';
  }

  @override
  String apiError(Object error) {
    return 'Error de GymOS API: $error';
  }

  @override
  String get breakfastShort => 'Desayuno';

  @override
  String get loginStatusPreparing => 'Preparando tu gimnasio...';

  @override
  String get loginStatusConnecting => 'Conectando a Google...';

  @override
  String get loginErrorCancelled => 'Sesión cancelada o fallida.';

  @override
  String get loginStatusDownloading => 'Descargando tu progreso...';

  @override
  String get loginStatusCreatingProfile => 'Creando tu perfil GymOS...';

  @override
  String get loginErrorSync =>
      'Error de sincronización. Verifica tu conexión e intenta nuevamente.';

  @override
  String get loginSubtitle => 'THE ULTIMATE FITNESS OS';

  @override
  String get loginContinueWithGoogle => 'CONTINUAR CON GOOGLE';

  @override
  String get copyMealsTo => 'Copiar Comidas';

  @override
  String get chooseDestinationDay =>
      'Elige el día de destino para los registros.';

  @override
  String get forToday => 'Para Hoy';

  @override
  String get forTomorrow => 'Para Mañana';

  @override
  String targetHasRecordsMessage(Object targetName) {
    return 'El día de $targetName ya contiene comidas. ¿Quieres añadir las nuevas a las existentes?';
  }

  @override
  String recordsInTarget(Object targetName) {
    return 'Registros en $targetName';
  }

  @override
  String mealsCopiedTargetSuccess(Object targetName) {
    return '¡Comidas copiadas a $targetName con éxito!';
  }

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get macroSmartPresetsTitle =>
      'ESTRATEGIAS RÁPIDAS (PRESETS INTELIGENTES)';

  @override
  String get macroDistributionSection => 'DISTRIBUCIÓN DE MACRONUTRIENTES';

  @override
  String macroCalculationBase(Object kcal) {
    return 'Calculado en base a tu meta diaria de $kcal kcal.';
  }

  @override
  String get macroStatusPerfect => 'DISTRIBUCIÓN PERFECTA';

  @override
  String macroStatusExcess(Object percent) {
    return 'EXCESO DE $percent%';
  }

  @override
  String macroStatusMissing(Object percent) {
    return 'FALTAN $percent%';
  }

  @override
  String get macroPresetBalanced => 'Equilibrado';

  @override
  String get macroPresetHypertrophy => 'Hipertrofia';

  @override
  String get macroPresetLowCarb => 'Bajo en Carbohidratos';

  @override
  String get profileSectionPersonal => 'DATOS PERSONALES';

  @override
  String get profileSectionBody => 'CUERPO Y ESTILO DE VIDA';

  @override
  String get profileSectionStrategy => 'ESTRATEGIA NUTRICIONAL';

  @override
  String get profileDone => 'Hecho';

  @override
  String get profileSelect => 'Seleccionar';

  @override
  String get activitySedentaryDesc => 'Poco o ningún ejercicio';

  @override
  String get activityLightDesc => 'Ejercicio ligero 1-3 días/semana';

  @override
  String get activityModerateDesc => 'Ejercicio moderado 3-5 días/semana';

  @override
  String get activityIntenseDesc => 'Ejercicio intenso 6-7 días/semana';

  @override
  String get activityAthleteDesc => 'Atleta o trabajo físico muy pesado';

  @override
  String get settingsBackupInProgress => 'Guardando tus datos en la nube...';

  @override
  String get settingsBackupSuccess =>
      '¡Copia de seguridad completada con éxito!';

  @override
  String settingsBackupError(Object error) {
    return 'Error al guardar en la nube: $error';
  }

  @override
  String get settingsRestoreWarningMsg =>
      'Esto reemplazará tus datos actuales con los datos guardados en tu cuenta de Google. ¿Quieres continuar?';

  @override
  String get settingsRestoreInProgress =>
      'Restaurando tus datos desde la nube...';

  @override
  String settingsRestoreError(Object error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get settingsLogoutTitle => 'Cerrar Sesión';

  @override
  String get settingsLogoutMessage =>
      '¿Estás seguro de que deseas cerrar sesión? Esto eliminará tus datos locales de este dispositivo (tus datos en la nube están seguros).';

  @override
  String settingsLogoutError(Object error) {
    return 'Error al cerrar sesión: $error';
  }

  @override
  String get settingsAutoSyncTitle => 'Sincronización Automática';

  @override
  String get settingsAutoSyncSubtitle =>
      'Guardar los cambios en la nube automáticamente';

  @override
  String get settingsBackupDataTitle => 'Hacer Copia de Seguridad';

  @override
  String get settingsBackupDataSubtitle =>
      'Forzar sincronización de datos con Google';

  @override
  String get settingsRestoreDataTitle => 'Restaurar Datos de la Nube';

  @override
  String get settingsRestoreDataSubtitle =>
      'Recuperar datos guardados anteriormente';

  @override
  String get settingsAccountSection => 'Cuenta';

  @override
  String get settingsLogoutItemTitle => 'Cerrar Sesión';

  @override
  String get settingsLogoutItemSubtitle =>
      'Cerrar sesión de tu cuenta y borrar datos locales';

  @override
  String get settingsLanguageMain => 'Versión Principal';

  @override
  String get settingsLanguageDev => 'En desarrollo';

  @override
  String get settingsLanguageDevWarning =>
      'Aviso: Idioma aún en desarrollo. Faltarán algunas traducciones.';

  @override
  String get unknown => 'Desconocido';

  @override
  String get duplicateWeightTitle => 'Peso ya registrado';

  @override
  String duplicateWeightMessage(String weight) {
    return 'Ya registraste $weight kg este día. ¿Quieres reemplazarlo por el nuevo valor?';
  }

  @override
  String get deleteWeightTitle => '¿Eliminar registro?';

  @override
  String deleteWeightMessage(String date) {
    return '¿Estás seguro de que quieres eliminar el registro del $date?';
  }

  @override
  String get generalCategory => 'General';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get onboardingNext => 'Continuar';

  @override
  String get onboardingFinish => 'Entrar a la App';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido\na GymOS.';

  @override
  String get onboardingWelcomeSubtitle =>
      'Tu compañero de entrenamiento y nutrición. Configuremos todo en menos de 2 minutos.';

  @override
  String get onboardingFeature1 => 'Registra tus comidas diarias';

  @override
  String get onboardingFeature2 => 'Sigue tu peso y evolución';

  @override
  String get onboardingFeature3 => 'Gestiona tus planes de entrenamiento';

  @override
  String get onboardingNameTitle => '¿Cómo te llamas?';

  @override
  String get onboardingNameSubtitle =>
      'Dinos tu nombre y género para personalizar tu experiencia.';

  @override
  String get onboardingNameHint => 'Tu nombre o apodo';

  @override
  String get onboardingGender => 'Género';

  @override
  String get onboardingBodyTitle => 'Datos corporales';

  @override
  String get onboardingBodySubtitle =>
      'Usamos estos datos para calcular tu metabolismo basal y meta calórica diaria.';

  @override
  String get onboardingSelectDate => 'Seleccionar fecha de nacimiento';

  @override
  String get onboardingActivityTitle => 'Nivel de actividad';

  @override
  String get onboardingActivitySubtitle =>
      'Elige el nivel que mejor describe tu rutina semanal actual.';

  @override
  String get onboardingThemeTitle => 'Elige tu tema';

  @override
  String get onboardingThemeSubtitle =>
      'Puedes cambiarlo en cualquier momento en los ajustes.';

  @override
  String get copyMeal => 'Copiar Comida';

  @override
  String get chooseMealType => '¿A qué comida?';

  @override
  String get startWorkout => 'INICIAR';

  @override
  String get chooseTrainingDay => 'Elige el Día de Entrenamiento';

  @override
  String get chooseTrainingDaySub =>
      'Selecciona el entrenamiento que harás hoy';

  @override
  String activeWorkoutOf(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get planned => 'Planeado';

  @override
  String get lastSession => 'Última sesión';

  @override
  String get noHistoryYet => 'Sin historial todavía';

  @override
  String get logSet => 'REGISTRAR SERIE';

  @override
  String get restLabel => 'Descanso';

  @override
  String get skipRest => 'SALTAR';

  @override
  String get nextExercise => 'Siguiente';

  @override
  String get prevExercise => 'Anterior';

  @override
  String get finishWorkout => 'TERMINAR';

  @override
  String get confirmFinishTitle => '¿Terminar Entrenamiento?';

  @override
  String get confirmFinishMsg =>
      'Tus series ya fueron guardadas en tiempo real. Puedes salir sin perder nada.';

  @override
  String get sessionDoneTitle => '¡Entrenamiento Completo! 💪';

  @override
  String get sessionTotalSets => 'Series totales';

  @override
  String get sessionTotalVolume => 'Volumen total';

  @override
  String get sessionDuration => 'Duración';

  @override
  String get sessionClose => 'CERRAR';

  @override
  String get newPR => '¡Nuevo Récord! 🏆';

  @override
  String get setsThisSession => 'ESTA SESIÓN';

  @override
  String get invalidSetInput => '¡Introduce peso y repeticiones válidos!';

  @override
  String get restAdjust => 'Ajustar descanso';

  @override
  String get yesterday => 'ayer';

  @override
  String daysAgo(int n) {
    return 'hace ${n}d';
  }

  @override
  String get exerciseLibraryTitle => 'Biblioteca de Ejercicios';

  @override
  String get exerciseSearchHint => 'Buscar ejercicios...';

  @override
  String get allFilter => 'Todos';

  @override
  String get createCustomExercise => 'Crear ejercicio personalizado';

  @override
  String get workoutTemplatesTitle => 'Plantillas de Entrenamiento';

  @override
  String get workoutTemplatesSub => 'Planes listos para usar';

  @override
  String get useThisTemplate => 'USAR ESTA PLANTILLA';

  @override
  String get settingsPersonalization => 'Personalización';

  @override
  String get settingsMealsSub => 'Editar, añadir y reordenar comidas';

  @override
  String settingsVersionLabel(String v) {
    return 'Versión $v';
  }

  @override
  String get errorNetwork => 'Fallo de red. Verifica tu internet.';

  @override
  String get errorRateLimit =>
      'Demasiadas búsquedas seguidas. Espera 1 minuto.';

  @override
  String get errorServerDown =>
      'La base de datos global está en mantenimiento.';

  @override
  String get errorServerSlow =>
      'Los servidores están muy lentos. Inténtalo de nuevo.';

  @override
  String get mealSettingsReset => 'Restablecer';

  @override
  String get mealSettingsAdd => 'Añadir';

  @override
  String get mealSettingsInfo =>
      'Arrastra para reordenar. Los registros pasados no se ven afectados al editar o eliminar.';

  @override
  String get mealNew => 'Nueva comida';

  @override
  String get mealEditTitle => 'Editar comida';

  @override
  String get mealDeleteTitle => '¿Eliminar comida?';

  @override
  String mealDeleteMsg(String name) {
    return 'La comida \"$name\" será eliminada de la lista.\n\nLos registros pasados no se verán afectados.';
  }

  @override
  String get mealResetTitle => '¿Restablecer lista original?';

  @override
  String get mealResetMsg =>
      'La lista se restablecerá a los valores predeterminados.\n\nLos registros pasados no se verán afectados.';

  @override
  String get mealRestoreAction => 'Restablecer';

  @override
  String get mealNameHint => 'Ej: Desayuno';

  @override
  String get saveAction => 'Guardar';

  @override
  String get editTooltip => 'Editar';

  @override
  String get deleteTooltip => 'Eliminar';

  @override
  String get nutritionSummary => 'Resumen Nutricional';

  @override
  String get byMeal => 'Por Comida';

  @override
  String get workoutSubtitle => 'Planes y Rutinas';

  @override
  String get toolsSubtitle => 'Calculadoras y Registros';

  @override
  String get greetingMorning => 'Buenos días';

  @override
  String get greetingAfternoon => 'Buenas tardes';

  @override
  String get greetingEvening => 'Buenas noches';
}
