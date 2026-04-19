import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AppConstants {
  // Estes valores são as "Chaves" guardadas na Base de Dados.
  // NÃO OS MUDES para não perder dados antigos ou quebrar a ordem.
  static const List<String> mealOrder = [
    "Peq. Almoço", // Ou "Pequeno-almoço" se for o que tens na BD
    "Almoço",
    "Lanche",
    "Jantar",
    "Pré-Treino",
    "Pós-Treino",
    "Ceia"
  ];
}

class TranslationHelper {
  static String getMealName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;

    switch (key.toLowerCase()) {
      case "peq. almoço":
      case "pequeno-almoço":
      case "pequeno":
        return l10n.mealBreakfast;
      case "almoço":
        return l10n.mealLunch;
      case "lanche":
        return l10n.mealSnack;
      case "jantar":
        return l10n.mealDinner;
      case "ceia":
        return l10n.mealSupper;
      case "pré-treino":
      case "pré":
        return l10n.mealPreWorkout;
      case "pós-treino":
      case "pós":
        return l10n.mealPostWorkout;
      case "outros":
        return l10n.mealOthers;
      default:
        return key;
    }
  }

  // Alias para retrocompatibilidade em outros ficheiros
  static String translateMeal(BuildContext context, String dbValue) {
    return getMealName(context, dbValue);
  }
}
