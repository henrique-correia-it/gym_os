// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get dashboardTitle => 'Painel';

  @override
  String get meals => 'Refeições';

  @override
  String get tools => 'Ferramentas';

  @override
  String get utilities => 'Utilidades';

  @override
  String get weight => 'Peso';

  @override
  String get history => 'Ver histórico';

  @override
  String get imc => 'IMC';

  @override
  String get addFood => 'Adicionar Alimento';

  @override
  String get viewDiary => 'Ver Diário';

  @override
  String get readOnly => 'Apenas Leitura';

  @override
  String get toolsWeightHistory => 'Histórico de Peso';

  @override
  String get toolsWeightHistorySub =>
      'Regista e acompanha a tua evolução corporal';

  @override
  String get toolsBatchCalc => 'Calculadora de Marmitas';

  @override
  String get toolsBatchCalcSub => 'Calcula macros de comida cozinhada';

  @override
  String get toolsCereal => 'Calculadora de Papas';

  @override
  String get toolsCerealSub => 'Mistura perfeita de Nestum/Cerelac e Líquidos';

  @override
  String get toolsWorkout => 'Plano de Treino';

  @override
  String get toolsWorkoutSub => 'Gere as tuas rotinas e exporta para PDF';

  @override
  String get navHome => 'Início';

  @override
  String get navDiet => 'Dieta';

  @override
  String get navWorkout => 'Treino';

  @override
  String get navTools => 'Ferram.';

  @override
  String get navProfile => 'Perfil';

  @override
  String get error => 'Erro';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get save => 'SALVAR';

  @override
  String get delete => 'APAGAR';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get required => 'Obrigatório';

  @override
  String get remaining => 'restam';

  @override
  String get exceeded => 'excedido';

  @override
  String get goal => 'Meta';

  @override
  String get consumed => 'Consumido';

  @override
  String get protein => 'Proteína';

  @override
  String get carbs => 'Hidratos';

  @override
  String get fat => 'Gordura';

  @override
  String get proteinShort => 'P';

  @override
  String get carbsShort => 'H';

  @override
  String get fatShort => 'G';

  @override
  String get noMealsRegistered => 'Sem refeições registadas';

  @override
  String get deleteMealTitle => 'Apagar Refeição?';

  @override
  String deleteMealMessage(Object name) {
    return 'Vais remover \'$name\' deste dia.';
  }

  @override
  String get mealRemoved => 'Refeição removida';

  @override
  String get errorRemoving => 'Erro ao remover';

  @override
  String edit(Object name) {
    return 'Editar $name';
  }

  @override
  String quantity(Object unit) {
    return 'Quantidade ($unit)';
  }

  @override
  String get updated => 'Atualizado!';

  @override
  String get mealBreakfast => 'Pequeno-almoço';

  @override
  String get mealLunch => 'Almoço';

  @override
  String get mealSnack => 'Lanche';

  @override
  String get mealDinner => 'Jantar';

  @override
  String get mealOthers => 'Outros';

  @override
  String get searchPlaceholder => 'O que vais comer hoje?';

  @override
  String get searchEmptyTitle =>
      'Pesquisa alimentos online ou\nna tua base de dados.';

  @override
  String createFood(Object name) {
    return 'Criar \'$name\'';
  }

  @override
  String get onlineLabel => 'Online';

  @override
  String get myFoodsLabel => 'Meus Alimentos';

  @override
  String get importAndEdit => 'IMPORTAR & EDITAR';

  @override
  String get editAction => 'EDITAR';

  @override
  String get addToDiary => 'ADICIONAR AO DIÁRIO';

  @override
  String foodAdded(Object name) {
    return '$name adicionado!';
  }

  @override
  String foodDeleted(Object name) {
    return '$name apagado.';
  }

  @override
  String get imported => 'Importado! A abrir editor...';

  @override
  String get errorConnection => 'Erro de conexão: Verifica a internet.';

  @override
  String get diary => 'Diário';

  @override
  String get feeding => 'Alimentação';

  @override
  String get createFoodTitle => 'Criar Alimento';

  @override
  String get editFoodTitle => 'Editar Alimento';

  @override
  String get foodName => 'Nome do Alimento';

  @override
  String get unit100g => '100g';

  @override
  String get unit1Unit => '1 Unidade';

  @override
  String get macrosHint => 'Macros (Podes usar vírgulas)';

  @override
  String get kcal => 'Kcal';

  @override
  String get saveChanges => 'SALVAR ALTERAÇÕES';

  @override
  String get createFoodAction => 'CRIAR ALIMENTO';

  @override
  String get duplicateFoodTitle => 'Alimento Repetido';

  @override
  String duplicateFoodMessage(Object name) {
    return 'Já existe um registo chamado \'$name\'.\nDesejas substituir os valores antigos pelos novos?';
  }

  @override
  String get replace => 'SUBSTITUIR';

  @override
  String get foodSaved => 'Alimento guardado!';

  @override
  String get configuration => 'Configuração';

  @override
  String get profileAndGoals => 'Perfil & Metas';

  @override
  String get dailyGoal => 'META DIÁRIA';

  @override
  String get bmr => 'Basal (BMR)';

  @override
  String get tdee => 'Gasto Total (TDEE)';

  @override
  String get fieldName => 'Nome (Apelido)';

  @override
  String get fieldHeight => 'Altura (cm)';

  @override
  String get currentWeight => 'Peso Atual (kg)';

  @override
  String get birthDate => 'Data de Nascimento';

  @override
  String get birthDateRequired => 'Data de nascimento obrigatória!';

  @override
  String years(Object count) {
    return '$count anos';
  }

  @override
  String get activityLevel => 'Nível de Atividade';

  @override
  String get activitySedentary => 'Sedentário';

  @override
  String get activityLight => 'Leve (1-3x/sem)';

  @override
  String get activityModerate => 'Moderado (3-5x/sem)';

  @override
  String get activityIntense => 'Intenso (6-7x/sem)';

  @override
  String get activityAthlete => 'Atleta (Bidiário)';

  @override
  String get caloricAdjustment => 'Ajuste Calórico';

  @override
  String get adjustmentHint => 'Ex: -300 (Cut), +200 (Bulk)';

  @override
  String get macroSettings => 'Metas de Macronutrientes';

  @override
  String get macroSettingsHint => 'Ajustar % de Prot / Carb / Gord';

  @override
  String get saveProfile => 'GUARDAR PERFIL';

  @override
  String get profileSaved => 'Perfil guardado e meta atualizada!';

  @override
  String get imcUnderweight => 'Abaixo';

  @override
  String get imcNormal => 'Normal';

  @override
  String get imcOverweight => 'Sobrepeso';

  @override
  String get imcObese => 'Obesidade';

  @override
  String get defaultUserNameAthlete => 'Atleta';

  @override
  String get defaultUserName => 'Utilizador';

  @override
  String get male => 'Masc.';

  @override
  String get female => 'Fem.';

  @override
  String get macroDistribution => 'Divisão de Macros';

  @override
  String get totalDistribution => 'Total da Distribuição';

  @override
  String get mustBe100 => 'A soma deve ser exatamente 100%';

  @override
  String get saveSettings => 'GUARDAR DEFINIÇÕES';

  @override
  String get goalsUpdated => 'Metas atualizadas!';

  @override
  String get preferences => 'Preferências';

  @override
  String get settings => 'Definições';

  @override
  String get general => 'Geral';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Language / Idioma';

  @override
  String get appearance => 'Aspeto';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeAmoled => 'Preto';

  @override
  String get dataBackup => 'Dados & Backup';

  @override
  String get exportData => 'Exportar Dados';

  @override
  String get exportDataSub => 'Guardar backup num ficheiro';

  @override
  String get importData => 'Importar Dados';

  @override
  String get importDataSub => 'Restaurar backup (Apaga atual)';

  @override
  String get about => 'Sobre';

  @override
  String get version => 'Versão';

  @override
  String get importWarningTitle => 'Atenção!';

  @override
  String get importWarningMessage =>
      'Isto vai APAGAR todos os dados atuais e substitui-los pelo backup.\nTens a certeza?';

  @override
  String get yesRestore => 'Sim, Restaurar';

  @override
  String get dataRestored => 'Dados restaurados!\nA reiniciar...';

  @override
  String get corruptFile => 'O ficheiro está corrompido ou inválido.';

  @override
  String get toolsBatchManager => 'Ajustar Marmitas';

  @override
  String get toolsBatchManagerSub =>
      'Edita os ingredientes de marmitas já criadas';

  @override
  String get toolsOneRepMax => 'Cálculo 1RM (Força)';

  @override
  String get toolsOneRepMaxSub => 'Estima a tua carga máxima e percentagens';

  @override
  String get toolsLoadTracker => 'Progressão de Cargas';

  @override
  String get toolsLoadTrackerSub =>
      'Monitoriza o teu aumento de força por exercício';

  @override
  String get toolsRealWeight => 'Calculadora de Peso Real';

  @override
  String get toolsRealWeightSub =>
      'Calibra o peso na tua balança baseado no peso real';

  @override
  String get newRecord => 'Novo Registo';

  @override
  String get confirmWeight => 'CONFIRMAR PESO';

  @override
  String get evolution => 'Evolução';

  @override
  String get weightAnalysis => 'Análise de Peso';

  @override
  String get register => 'REGISTAR';

  @override
  String get noWeightRecords => 'Sem registos de peso.';

  @override
  String get recentHistory => 'HISTÓRICO RECENTE';

  @override
  String get myWorkouts => 'Meus Treinos';

  @override
  String get newWorkout => 'NOVO TREINO';

  @override
  String get createFirstRoutine => 'Cria a tua primeira rotina de treino';

  @override
  String get workoutEmptyTitle => 'Pronto para treinar?';

  @override
  String get workoutEmptySubtitle =>
      'Cria o teu primeiro plano personalizado ou começa rapidamente com um dos nossos templates.';

  @override
  String get workoutEmptyCreateOwn => 'Criar do zero';

  @override
  String get workoutEmptyUseTemplate => 'Usar um template';

  @override
  String get tapToEdit => 'Toca para editar ou exportar PDF';

  @override
  String get deletePlanTitle => 'Apagar Plano';

  @override
  String deletePlanMessage(Object name) {
    return 'Queres mesmo eliminar o \'$name\'?';
  }

  @override
  String get renameSession => 'Renomear Sessão';

  @override
  String get addExercise => 'Adicionar Exercício';

  @override
  String get add => 'ADICIONAR';

  @override
  String get session => 'SESSÃO';

  @override
  String get noExercises => 'Sem exercícios';

  @override
  String get addFirst => 'Adicionar Primeiro';

  @override
  String get addExerciseAction => 'ADICIONAR EXERCÍCIO';

  @override
  String get loads => 'Cargas';

  @override
  String get selectExercise => 'Seleciona o exercício';

  @override
  String get newSet => 'NOVA SÉRIE';

  @override
  String get recordProgress => 'REGISTAR PROGRESSO';

  @override
  String get loadEvolution => 'EVOLUÇÃO DE CARGA';

  @override
  String get realWeight => 'Peso Real';

  @override
  String get oneRepMaxCalc => 'Cálculo 1RM';

  @override
  String get testPerformed => 'TESTE REALIZADO';

  @override
  String get intensity => 'Intensidade';

  @override
  String get loadAndReps => 'Carga & Reps';

  @override
  String get finalAdjustment => 'Ajuste Final & Confirmar';

  @override
  String get batchCalcTitle => 'Calculadora';

  @override
  String get batchCalcAdjust => 'Ajustar';

  @override
  String get batchCalcMarmita => 'Marmita';

  @override
  String get batchCalcNameHint => 'Nome da Receita';

  @override
  String get batchCalcYield => 'RENDE';

  @override
  String get batchCalcDoses => 'DOSES';

  @override
  String get batchCalcPerDose => 'POR DOSE';

  @override
  String get batchCalcIngredients => 'Ingredientes';

  @override
  String batchCalcItems(Object count) {
    return '$count itens';
  }

  @override
  String get batchCalcAdd => 'ADICIONAR';

  @override
  String get batchCalcSaveAdjustments => 'GUARDAR AJUSTES';

  @override
  String get batchCalcSearchIngredient => 'Pesquisar Ingrediente';

  @override
  String batchCalcEditIngredient(Object name) {
    return 'Editar $name';
  }

  @override
  String get batchCalcNoIngredients => 'Adiciona ingredientes primeiro!';

  @override
  String get batchCalcNameRequired => 'Dá um nome à marmita!';

  @override
  String get batchCalcDosesError => 'O número de doses tem de ser maior que 0!';

  @override
  String get cerealCalcCalorieGoal => 'META DE CALORIAS';

  @override
  String get cerealCalcCereal => 'Cereal';

  @override
  String get cerealCalcLiquid => 'Líquido';

  @override
  String get cerealCalcWater => 'Água';

  @override
  String get cerealCalcSelect => 'Selecionar';

  @override
  String get cerealCalcAdjustVolume => 'Ajustar Volume Líquido?';

  @override
  String get cerealCalcAdjustVolumeSub => 'Define a qtd. total da taça';

  @override
  String get cerealCalcTotalVolume => 'Volume Total';

  @override
  String get cerealCalcCalculatedRecipe => 'RECEITA CALCULADA';

  @override
  String cerealCalcEstimate(Object kcal) {
    return 'Estimativa: $kcal kcal';
  }

  @override
  String get cerealCalcConfigureFirst => 'Configura a receita primeiro!';

  @override
  String get cerealCalcAddAsDose => 'ADICIONAR COMO 1 DOSE';

  @override
  String get cerealCalcAdded => 'Receita adicionada (1 un)!';

  @override
  String get cerealCalcChooseLiquid => 'Escolher Líquido';

  @override
  String get cerealCalcChooseCereal => 'Escolher Cereal';

  @override
  String get exerciseName => 'Nome do Exercício';

  @override
  String get sets => 'Séries';

  @override
  String get reps => 'Reps';

  @override
  String get restSeconds => 'Descanso (s)';

  @override
  String get weightKg => 'Carga (kg)';

  @override
  String get notes => 'Notas';

  @override
  String get addSet => 'Adicionar Série';

  @override
  String yearsOld(Object age) {
    return '$age anos';
  }

  @override
  String get birthDateLabel => 'Data de Nascimento';

  @override
  String get currentWeightLabel => 'Peso Atual (kg)';

  @override
  String get macroSettingsTitle => 'Metas de Macronutrientes';

  @override
  String get macroSettingsSubtitle => 'Ajustar % de Prot / Carb / Gord';

  @override
  String duplicateFoodMsg(Object name) {
    return 'Já existe um registo chamado \'$name\'. Desejas substituir os valores antigos pelos novos?';
  }

  @override
  String get sourceMarmita => 'Marmita Calc';

  @override
  String get ingredientType => 'Ingrediente';

  @override
  String get others => 'Outros';

  @override
  String get unitKcal => 'kcal';

  @override
  String get unitG => 'g';

  @override
  String get unitUn => 'un';

  @override
  String get weightHistoryTitle => 'Histórico de Peso';

  @override
  String get weightHistoryNoData => 'Sem dados suficientes para o gráfico.';

  @override
  String get batchManagerTitle => 'Gerir Marmitas';

  @override
  String get batchManagerIngredients => 'Ingredientes';

  @override
  String get loadTrackerTitle => 'Evolução de Cargas';

  @override
  String get loadTrackerExercise => 'Exercício';

  @override
  String get loadTrackerWeight => 'Carga (kg)';

  @override
  String get loadTrackerReps => 'Repetições';

  @override
  String get loadTrackerChart => 'Gráfico de Evolução';

  @override
  String get oneRmTitle => 'Calculadora 1RM';

  @override
  String get oneRmCalculate => 'CALCULAR 1RM';

  @override
  String get oneRmResult => 'O teu 1RM Estimado';

  @override
  String get oneRmInstructions =>
      'Insere uma carga e quantas repetições consegues fazer com ela.';

  @override
  String get realWeightTitle => 'Peso Real vs Balança';

  @override
  String get realWeightExplanation =>
      'Usa isto para calibrar a diferença entre pesagens em jejum e pesagens durante o dia.';

  @override
  String get realWeightScale => 'Peso na Balança';

  @override
  String get realWeightTrue => 'Peso Real Estimado';

  @override
  String get dietTitle => 'Dieta';

  @override
  String get dietNutrition => 'Alimentação';

  @override
  String get mealPreWorkout => 'Pré-Treino';

  @override
  String get mealPostWorkout => 'Pós-Treino';

  @override
  String get workoutNewPlan => 'Novo Plano';

  @override
  String get workoutSessionDefault => 'Treino';

  @override
  String get workoutRename => 'Renomear Sessão';

  @override
  String get workoutNameHint => 'Nome (ex: Puxar, Pernas)';

  @override
  String get workoutAddExerciseTitle => 'Adicionar Exercício';

  @override
  String get workoutExerciseName => 'Nome do Exercício';

  @override
  String get workoutPdfFooter => 'Gerado por GymOS • Fica forte!';

  @override
  String get workoutSaveSuccess => 'Plano guardado com sucesso!';

  @override
  String get workoutSaveError => 'Erro ao salvar';

  @override
  String get workoutPlanNameHint => 'Nome do Plano';

  @override
  String get workoutExportPdf => 'Exportar PDF';

  @override
  String get workoutNewSession => 'Nova Sessão';

  @override
  String get workoutDeleteSession => 'Apagar Sessão';

  @override
  String get workoutAddFirst => 'Adicionar Primeiro';

  @override
  String get workoutMinDays => 'O plano tem de ter pelo menos 1 dia.';

  @override
  String get workoutNameRequired => 'Dá um nome ao plano!';

  @override
  String get rwCalibration => '1. CALIBRAÇÃO (BALANÇA VS REAL)';

  @override
  String get rwRealWeightShop => 'Peso Real (Talho)';

  @override
  String get rwScaleWeight => 'Na Tua Balança';

  @override
  String get rwGoal => '2. O TEU OBJETIVO';

  @override
  String get rwGoalWeight => 'Peso Real que queres no final';

  @override
  String get rwInstructions => 'INSTRUÇÕES PARA PESAGEM';

  @override
  String get rwScaleTarget => 'Para quando a balança marcar isto';

  @override
  String get rwScaleRemove => 'Total a retirar na balança';

  @override
  String get rwVerification => '3. VERIFICAÇÃO FINAL';

  @override
  String get rwScaleRemovedActual => 'Quanto retiraste na balança?';

  @override
  String get rwResultReal => 'RESULTADO REAL OBTIDO';

  @override
  String get rwFinalWeight => 'Peso real que ficou no prato';

  @override
  String get rwRemovedReal => 'Peso real retirado';

  @override
  String get ormPureStrength => 'Força Pura';

  @override
  String get ormHypertrophy => 'Hipertrofia';

  @override
  String get ormEndurance => 'Resistência';

  @override
  String get ormExplosion => 'Cardio/Explosão';

  @override
  String get ormFillData => 'Preenche os dados acima\npara gerar a tabela.';

  @override
  String get backupShareText => 'Backup GymOS';

  @override
  String get setSaved => 'Série registada!';

  @override
  String get recordDeleted => 'Registo apagado';

  @override
  String get startBySelecting =>
      'Começa por selecionar um exercício\npara veres o teu progresso.';

  @override
  String get batchEmpty => 'Nenhuma marmita encontrada';

  @override
  String get batchDeleteTitle => 'Apagar Marmita';

  @override
  String batchDeleteConfirm(Object name) {
    return 'Tens a certeza que queres eliminar a receita de \'$name\'?';
  }

  @override
  String get cerealCalcEditIngredients => 'Ingredientes (Editar)';

  @override
  String get mealSupper => 'Ceia';

  @override
  String get copyMealsToTomorrow => 'Copiar refeições para amanhã';

  @override
  String get clearDay => 'Limpar dia';

  @override
  String get clearDayTitle => 'Limpar dia?';

  @override
  String get clearDayMessage =>
      'Isto apagará todas as refeições deste dia. Esta ação não pode ser desfeita.';

  @override
  String get deleteAll => 'Apagar Tudo';

  @override
  String get dayClearedSuccess => 'Dia limpo com sucesso!';

  @override
  String errorClearingDay(Object error) {
    return 'Erro ao limpar dia: $error';
  }

  @override
  String get tomorrowHasRecords => 'Amanhã já tem registos';

  @override
  String get tomorrowHasRecordsMessage =>
      'O dia de amanhã já contém refeições. Deseja adicionar as refeições de hoje à lista existente?';

  @override
  String get mealsCopiedSuccess =>
      'Refeições de hoje copiadas para amanhã com sucesso!';

  @override
  String errorCopying(Object error) {
    return 'Erro ao copiar: $error';
  }

  @override
  String get selectMealError => 'Por favor selecione uma refeição';

  @override
  String exportError(Object error) {
    return 'Erro ao exportar: $error';
  }

  @override
  String openFileError(Object error) {
    return 'Erro ao abrir ficheiro: $error';
  }

  @override
  String get searchWord => 'Pesquisar...';

  @override
  String get maxStrength => 'FORÇA MÁXIMA';

  @override
  String get liquidAdjustMode => 'Modo de Ajuste Líquido';

  @override
  String porridgeOf(Object name) {
    return 'Papas de $name';
  }

  @override
  String get workoutDeleted => 'Treino removido';

  @override
  String criticalDbError(Object error) {
    return 'ERRO CRÍTICO AO INICIAR DB: $error';
  }

  @override
  String get myFavorites => 'Meus Favoritos';

  @override
  String importDataError(Object error) {
    return 'Erro ao importar dados: $error';
  }

  @override
  String get backupRestoredSuccess => 'Backup restaurado com sucesso!';

  @override
  String fatalRestoreError(Object error) {
    return 'Erro fatal ao restaurar backup: $error';
  }

  @override
  String get versionAlpha => 'v1.0.0 Alpha';

  @override
  String get madeWithLove => 'Feito com ❤️ para ti';

  @override
  String get batchCalcShort => 'Calc. Lotes';

  @override
  String serverError(Object code) {
    return 'Erro no servidor: $code';
  }

  @override
  String apiError(Object error) {
    return 'GymOS API Erro: $error';
  }

  @override
  String get breakfastShort => 'Peq. Almoço';

  @override
  String get loginStatusPreparing => 'A preparar o teu ginásio...';

  @override
  String get loginStatusConnecting => 'A ligar ao Google...';

  @override
  String get loginErrorCancelled => 'Sessão cancelada ou falhou.';

  @override
  String get loginStatusDownloading => 'A descarregar o teu progresso...';

  @override
  String get loginStatusCreatingProfile => 'A criar o teu perfil GymOS...';

  @override
  String get loginErrorSync =>
      'Erro na sincronização. Verifica a tua ligação e tenta novamente.';

  @override
  String get loginSubtitle => 'THE ULTIMATE FITNESS OS';

  @override
  String get loginContinueWithGoogle => 'CONTINUAR COM GOOGLE';

  @override
  String get copyMealsTo => 'Copiar Refeições';

  @override
  String get chooseDestinationDay =>
      'Escolhe o dia de destino para os registos.';

  @override
  String get forToday => 'Para Hoje';

  @override
  String get forTomorrow => 'Para Amanhã';

  @override
  String targetHasRecordsMessage(Object targetName) {
    return 'O dia de $targetName já contém refeições registadas. Queres adicionar as novas refeições às que já existem?';
  }

  @override
  String recordsInTarget(Object targetName) {
    return 'Registos em $targetName';
  }

  @override
  String mealsCopiedTargetSuccess(Object targetName) {
    return 'Refeições copiadas para $targetName com sucesso!';
  }

  @override
  String get today => 'Hoje';

  @override
  String get tomorrow => 'Amanhã';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get macroSmartPresetsTitle => 'ESTRATÉGIAS RÁPIDAS (SMART PRESETS)';

  @override
  String get macroDistributionSection => 'DISTRIBUIÇÃO DE MACRONUTRIENTES';

  @override
  String macroCalculationBase(Object kcal) {
    return 'Calculado com base na tua meta diária de $kcal kcal.';
  }

  @override
  String get macroStatusPerfect => 'DISTRIBUIÇÃO PERFEITA';

  @override
  String macroStatusExcess(Object percent) {
    return 'EXCESSO DE $percent%';
  }

  @override
  String macroStatusMissing(Object percent) {
    return 'FALTAM $percent%';
  }

  @override
  String get macroPresetBalanced => 'Equilibrado';

  @override
  String get macroPresetHypertrophy => 'Hipertrofia';

  @override
  String get macroPresetLowCarb => 'Low Carb';

  @override
  String get profileSectionPersonal => 'DADOS PESSOAIS';

  @override
  String get profileSectionBody => 'CORPO & ESTILO DE VIDA';

  @override
  String get profileSectionStrategy => 'ESTRATÉGIA NUTRICIONAL';

  @override
  String get profileDone => 'Concluído';

  @override
  String get profileSelect => 'Selecionar';

  @override
  String get activitySedentaryDesc => 'Pouco ou nenhum exercício';

  @override
  String get activityLightDesc => 'Exercício leve 1 a 3 dias/semana';

  @override
  String get activityModerateDesc => 'Exercício moderado 3 a 5 dias/semana';

  @override
  String get activityIntenseDesc => 'Exercício intenso 6 a 7 dias/semana';

  @override
  String get activityAthleteDesc => 'Atleta ou trabalho físico muito pesado';

  @override
  String get settingsBackupInProgress => 'A guardar os teus dados na nuvem...';

  @override
  String get settingsBackupSuccess =>
      'Cópia de segurança concluída com sucesso!';

  @override
  String settingsBackupError(Object error) {
    return 'Erro ao guardar na nuvem: $error';
  }

  @override
  String get settingsRestoreWarningMsg =>
      'Isto irá substituir os teus dados atuais pelos que estão guardados na tua conta Google. Queres continuar?';

  @override
  String get settingsRestoreInProgress =>
      'A restaurar os teus dados da nuvem...';

  @override
  String settingsRestoreError(Object error) {
    return 'Erro ao restaurar: $error';
  }

  @override
  String get settingsLogoutTitle => 'Terminar Sessão';

  @override
  String get settingsLogoutMessage =>
      'Tens a certeza que queres terminar a sessão? Isto irá remover os teus dados locais deste dispositivo (os dados na nuvem estão seguros).';

  @override
  String settingsLogoutError(Object error) {
    return 'Erro ao terminar sessão: $error';
  }

  @override
  String get settingsAutoSyncTitle => 'Sincronização Automática';

  @override
  String get settingsAutoSyncSubtitle =>
      'Guardar alterações na nuvem de forma automática';

  @override
  String get settingsBackupDataTitle => 'Fazer Cópia de Segurança';

  @override
  String get settingsBackupDataSubtitle =>
      'Forçar sincronização de dados com o Google';

  @override
  String get settingsRestoreDataTitle => 'Restaurar Dados da Nuvem';

  @override
  String get settingsRestoreDataSubtitle =>
      'Recuperar dados guardados anteriormente';

  @override
  String get settingsAccountSection => 'Conta';

  @override
  String get settingsLogoutItemTitle => 'Terminar Sessão';

  @override
  String get settingsLogoutItemSubtitle =>
      'Sair da tua conta e limpar dados locais';

  @override
  String get settingsLanguageMain => 'Versão Principal';

  @override
  String get settingsLanguageDev => 'Em desenvolvimento';

  @override
  String get settingsLanguageDevWarning =>
      'Aviso: Idioma ainda em desenvolvimento. Algumas traduções vão estar em falta.';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get duplicateWeightTitle => 'Peso já registado';

  @override
  String duplicateWeightMessage(String weight) {
    return 'Já registaste $weight kg neste dia. Queres substituir pelo novo valor?';
  }

  @override
  String get deleteWeightTitle => 'Apagar registo?';

  @override
  String deleteWeightMessage(String date) {
    return 'Tens a certeza que queres apagar o registo de $date?';
  }

  @override
  String get generalCategory => 'Geral';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get onboardingNext => 'Continuar';

  @override
  String get onboardingFinish => 'Entrar na App';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo\nao GymOS.';

  @override
  String get onboardingWelcomeSubtitle =>
      'O teu companheiro de treino e nutrição. Vamos configurar tudo em menos de 2 minutos.';

  @override
  String get onboardingFeature1 => 'Regista as tuas refeições diárias';

  @override
  String get onboardingFeature2 => 'Acompanha o teu peso e evolução';

  @override
  String get onboardingFeature3 => 'Gere os teus planos de treino';

  @override
  String get onboardingNameTitle => 'Como te chamas?';

  @override
  String get onboardingNameSubtitle =>
      'Diz-nos o teu nome e género para personalizarmos a tua experiência.';

  @override
  String get onboardingNameHint => 'O teu nome ou apelido';

  @override
  String get onboardingGender => 'Género';

  @override
  String get onboardingBodyTitle => 'Dados corporais';

  @override
  String get onboardingBodySubtitle =>
      'Usamos estes dados para calcular o teu metabolismo basal e meta calórica diária.';

  @override
  String get onboardingSelectDate => 'Selecionar data de nascimento';

  @override
  String get onboardingActivityTitle => 'Nível de atividade';

  @override
  String get onboardingActivitySubtitle =>
      'Escolhe o nível que melhor descreve a tua rotina semanal atual.';

  @override
  String get onboardingThemeTitle => 'Escolhe o teu tema';

  @override
  String get onboardingThemeSubtitle =>
      'Podes sempre mudar isto mais tarde nas definições.';

  @override
  String get copyMeal => 'Copiar Refeição';

  @override
  String get chooseMealType => 'Para que refeição?';

  @override
  String get startWorkout => 'INICIAR';

  @override
  String get chooseTrainingDay => 'Escolhe o Dia de Treino';

  @override
  String get chooseTrainingDaySub => 'Seleciona o treino que vais fazer hoje';

  @override
  String activeWorkoutOf(Object current, Object total) {
    return '$current / $total';
  }

  @override
  String get planned => 'Planeado';

  @override
  String get lastSession => 'Última sessão';

  @override
  String get noHistoryYet => 'Sem histórico ainda';

  @override
  String get logSet => 'REGISTAR SÉRIE';

  @override
  String get restLabel => 'Descanso';

  @override
  String get skipRest => 'SALTAR';

  @override
  String get nextExercise => 'Próximo';

  @override
  String get prevExercise => 'Anterior';

  @override
  String get finishWorkout => 'TERMINAR';

  @override
  String get confirmFinishTitle => 'Terminar Treino?';

  @override
  String get confirmFinishMsg =>
      'As tuas séries já foram guardadas em tempo real. Podes sair sem perder nada.';

  @override
  String get sessionDoneTitle => 'Treino Concluído! 💪';

  @override
  String get sessionTotalSets => 'Séries totais';

  @override
  String get sessionTotalVolume => 'Volume total';

  @override
  String get sessionDuration => 'Duração';

  @override
  String get sessionClose => 'FECHAR';

  @override
  String get newPR => 'Novo Recorde! 🏆';

  @override
  String get setsThisSession => 'ESTA SESSÃO';

  @override
  String get invalidSetInput => 'Insere carga e repetições válidas!';

  @override
  String get restAdjust => 'Ajustar descanso';

  @override
  String get yesterday => 'ontem';

  @override
  String daysAgo(int n) {
    return 'há ${n}d';
  }

  @override
  String get exerciseLibraryTitle => 'Biblioteca de Exercícios';

  @override
  String get exerciseSearchHint => 'Pesquisar exercícios...';

  @override
  String get allFilter => 'Todos';

  @override
  String get createCustomExercise => 'Criar exercício personalizado';

  @override
  String get workoutTemplatesTitle => 'Templates de Treino';

  @override
  String get workoutTemplatesSub => 'Planos prontos a usar';

  @override
  String get useThisTemplate => 'USAR ESTE TEMPLATE';

  @override
  String get settingsPersonalization => 'Personalização';

  @override
  String get settingsMealsSub => 'Editar, adicionar e reordenar refeições';

  @override
  String settingsVersionLabel(String v) {
    return 'Versão $v';
  }

  @override
  String get errorNetwork => 'Falha de rede. Verifica a internet.';

  @override
  String get errorRateLimit => 'Muitas pesquisas seguidas. Aguarda 1 minuto.';

  @override
  String get errorServerDown => 'A base de dados global está em manutenção.';

  @override
  String get errorServerSlow =>
      'Os servidores estão muito lentos. Tenta novamente.';

  @override
  String get mealSettingsReset => 'Repor padrão';

  @override
  String get mealSettingsAdd => 'Adicionar';

  @override
  String get mealSettingsInfo =>
      'Arrasta para reordenar. Os registos passados não são afetados ao editar ou apagar.';

  @override
  String get mealNew => 'Nova refeição';

  @override
  String get mealEditTitle => 'Editar refeição';

  @override
  String get mealDeleteTitle => 'Apagar refeição?';

  @override
  String mealDeleteMsg(String name) {
    return 'A refeição \"$name\" será removida da lista.\n\nOs registos passados não serão afetados.';
  }

  @override
  String get mealResetTitle => 'Repor lista original?';

  @override
  String get mealResetMsg =>
      'A lista será reposta para os valores padrão.\n\nOs registos passados não serão afetados.';

  @override
  String get mealRestoreAction => 'Repor';

  @override
  String get mealNameHint => 'Ex: Pequeno-Almoço';

  @override
  String get saveAction => 'Guardar';

  @override
  String get editTooltip => 'Editar';

  @override
  String get deleteTooltip => 'Apagar';

  @override
  String get nutritionSummary => 'Resumo Nutricional';

  @override
  String get byMeal => 'Por Refeição';
}
