import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class WeightEntry {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late DateTime date;
  late double weight;
}

@collection
class UserSettings {
  Id id = Isar.autoIncrement;
  String name = "Utilizador";
  String gender = "M";
  DateTime? birthDate;
  double weight = 70.0;
  double height = 175.0;
  double activityLevel = 1.2;
  String goal = "manter";
  double macroProtein = 0.30;
  double macroCarbs = 0.40;
  double macroFat = 0.30;
  double caloricAdjustment = 0.0;
  String? avatarPath;
  String themePersistence = "system";
  String language = "pt";
  bool autoSync = true;
  String? uid;

  @ignore
  int get age {
    if (birthDate == null) return 25;
    final now = DateTime.now();
    int calculatedAge = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }
  List<String> hiddenGlobalFoods = [];
  List<String> customMealOrder = [];
}
