import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});