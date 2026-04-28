import 'package:isar/isar.dart';

part 'workout.g.dart';

@collection
class WorkoutPlan {
  Id id = Isar.autoIncrement;
  @Index(type: IndexType.value, caseSensitive: false)
  late String name;
  final days = IsarLinks<WorkoutDay>();
  DateTime lastUpdated = DateTime.now();
}

@collection
class WorkoutDay {
  Id id = Isar.autoIncrement;
  late String name;
  final exercises = IsarLinks<WorkoutExercise>();
}

@collection
class WorkoutExercise {
  Id id = Isar.autoIncrement;
  late String name;
  late int sets;
  late String reps;
  late double weight;
  String? notes;
}

@collection
class ExerciseSet {
  Id id = Isar.autoIncrement;
  @Index()
  late String exerciseName;
  late double weight;
  late int reps;
  late DateTime date;
  @Index()
  String? sessionId;
}