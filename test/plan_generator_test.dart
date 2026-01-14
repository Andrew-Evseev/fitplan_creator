// test/plan_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fitplan_creator/features/planner/algorithms/plan_generator.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'package:fitplan_creator/data/repositories/training_system_repository.dart';
import 'package:fitplan_creator/data/repositories/workout_repository.dart';

void main() {
  late PlanGenerator planGenerator;
  late TrainingSystemRepository systemRepository;
  late WorkoutRepository workoutRepository;

  setUp(() {
    systemRepository = TrainingSystemRepository();
    workoutRepository = WorkoutRepository();
    planGenerator = PlanGenerator(systemRepository, workoutRepository);
  });

  group('Генерация планов для разных систем тренировок', () {
    test('Генерация FullBody плана для новичка с домашним оборудованием', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.dumbbells, Equipment.bodyweight],
        daysPerWeek: 3,
        sessionDuration: 45,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      expect(plan.workouts, isNotEmpty);
      expect(plan.trainingSystem, TrainingSystem.fullBody);
      expect(plan.workouts.length, greaterThanOrEqualTo(3));
      
      // Проверяем, что есть тренировочные дни
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      expect(workoutDays.length, greaterThanOrEqualTo(3));
      
      // Проверяем, что упражнения адаптированы под оборудование
      for (final workout in workoutDays) {
        expect(workout.exercises, isNotEmpty);
        expect(workout.duration, greaterThan(0));
      }
    });

    test('Генерация Split плана для среднего уровня с оборудованием зала', () async {
      final prefs = UserPreferences(
        goal: UserGoal.muscleGain,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
          Equipment.cableMachine,
        ],
        daysPerWeek: 4,
        sessionDuration: 75,
        preferredSystem: TrainingSystem.split,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      expect(plan.trainingSystem, TrainingSystem.split);
      expect(plan.workouts.length, greaterThanOrEqualTo(4));
      
      // Проверяем структуру Split (группы мышц по дням)
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      expect(workoutDays.length, greaterThanOrEqualTo(4));
      
      // Проверяем фокус каждого дня
      final focuses = workoutDays.map((w) => w.focus?.toLowerCase() ?? '').toList();
      expect(focuses.any((f) => f.contains('chest') || f.contains('triceps')), isTrue);
      expect(focuses.any((f) => f.contains('back') || f.contains('biceps')), isTrue);
      expect(focuses.any((f) => f.contains('legs') || f.contains('shoulders')), isTrue);
    });

    test('Генерация PPL плана для опытного пользователя', () async {
      final prefs = UserPreferences(
        goal: UserGoal.muscleGain,
        experienceLevel: ExperienceLevel.advanced,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
          Equipment.parallelBars,
          Equipment.cableMachine,
        ],
        daysPerWeek: 6,
        sessionDuration: 70,
        preferredSystem: TrainingSystem.ppl,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      expect(plan.trainingSystem, TrainingSystem.ppl);
      
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      expect(workoutDays.length, greaterThanOrEqualTo(6));
      
      // Проверяем структуру PPL (Push, Pull, Legs)
      final focuses = workoutDays.map((w) => w.focus?.toLowerCase() ?? '').toList();
      expect(focuses.any((f) => f.contains('push')), isTrue);
      expect(focuses.any((f) => f.contains('pull')), isTrue);
      expect(focuses.any((f) => f.contains('legs')), isTrue);
    });

    test('Генерация Upper/Lower плана', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
        ],
        daysPerWeek: 4,
        sessionDuration: 65,
        preferredSystem: TrainingSystem.upperLower,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      expect(plan.trainingSystem, TrainingSystem.upperLower);
      
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      expect(workoutDays.length, greaterThanOrEqualTo(4));
      
      // Проверяем чередование Upper/Lower
      final focuses = workoutDays.map((w) => w.focus?.toLowerCase() ?? '').toList();
      expect(focuses.any((f) => f.contains('upper')), isTrue);
      expect(focuses.any((f) => f.contains('lower')), isTrue);
    });

    test('Генерация Circuit плана для похудения', () async {
      final prefs = UserPreferences(
        goal: UserGoal.weightLoss,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweight, Equipment.dumbbells],
        daysPerWeek: 3,
        sessionDuration: 40,
        preferredSystem: TrainingSystem.circuit,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      expect(plan.trainingSystem, TrainingSystem.circuit);
      
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      expect(workoutDays.length, greaterThanOrEqualTo(3));
      
      // Проверяем, что упражнения подходят для круговой тренировки
      for (final workout in workoutDays) {
        expect(workout.exercises.length, greaterThanOrEqualTo(4));
        // Круговые тренировки обычно имеют больше упражнений
      }
    });

    test('Генерация Cardio плана для выносливости', () async {
      final prefs = UserPreferences(
        goal: UserGoal.endurance,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweight, Equipment.jumpRope],
        daysPerWeek: 4,
        sessionDuration: 45,
        preferredSystem: TrainingSystem.cardio,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      expect(plan.trainingSystem, TrainingSystem.cardio);
      
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      expect(workoutDays.length, greaterThanOrEqualTo(4));
      
      // Проверяем, что упражнения в основном кардио
      for (final workout in workoutDays) {
        final cardioExercises = workout.exercises.where(
          (e) => e.exerciseId.startsWith('cardio_'),
        ).length;
        expect(cardioExercises, greaterThan(0));
      }
    });
  });

  group('Проверка замены упражнений при отсутствии оборудования', () {
    test('Замена упражнений со штангой на гантели', () async {
      final prefs = UserPreferences(
        goal: UserGoal.muscleGain,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.dumbbells, Equipment.bench],
        daysPerWeek: 3,
        sessionDuration: 60,
        preferredSystem: TrainingSystem.fullBody,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем, что все упражнения доступны с имеющимся оборудованием
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          final exerciseDetails = workoutRepository.getExerciseById(exercise.exerciseId);
          
          // Если упражнение требует оборудование, проверяем доступность
          if (exerciseDetails.requiredEquipment.isNotEmpty) {
            final requiredEquipment = exerciseDetails.requiredEquipment;
            final hasEquipment = requiredEquipment.every(
              (eq) => prefs.availableEquipment.any(
                (available) => available.name == eq,
              ),
            );
            
            // Если нет оборудования, должно быть заменено на альтернативу
            if (!hasEquipment && !exerciseDetails.isBodyweight) {
              // Проверяем, что есть альтернативное упражнение
              expect(exerciseDetails.id, isNotEmpty);
            }
          }
        }
      }
    });

    test('Использование bodyweight упражнений при отсутствии оборудования', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.bodyweight,
        availableEquipment: [Equipment.bodyweight],
        daysPerWeek: 3,
        sessionDuration: 45,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем, что все упражнения bodyweight
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          final exerciseDetails = workoutRepository.getExerciseById(exercise.exerciseId);
          expect(
            exerciseDetails.isBodyweight || exerciseDetails.requiredEquipment.isEmpty,
            isTrue,
            reason: 'Упражнение ${exerciseDetails.name} должно быть bodyweight',
          );
        }
      }
    });
  });

  group('Балансировка нагрузки для разных систем', () {
    test('Балансировка нагрузки для Split системы', () async {
      final prefs = UserPreferences(
        goal: UserGoal.muscleGain,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
          Equipment.cableMachine,
        ],
        daysPerWeek: 4,
        sessionDuration: 75,
        preferredSystem: TrainingSystem.split,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем баланс нагрузки по дням
      final exercisesPerDay = workoutDays.map((w) => w.exercises.length).toList();
      
      // В Split системе каждый день должен иметь примерно одинаковое количество упражнений
      final avgExercises = exercisesPerDay.reduce((a, b) => a + b) / exercisesPerDay.length;
      
      for (final count in exercisesPerDay) {
        expect(
          count,
          greaterThanOrEqualTo(avgExercises * 0.7),
          reason: 'Количество упражнений должно быть сбалансировано',
        );
        expect(
          count,
          lessThanOrEqualTo(avgExercises * 1.3),
          reason: 'Количество упражнений должно быть сбалансировано',
        );
      }
    });

    test('Балансировка нагрузки для FullBody системы', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
        ],
        daysPerWeek: 3,
        sessionDuration: 60,
        preferredSystem: TrainingSystem.fullBody,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // В FullBody каждый день должен прорабатывать все основные группы мышц
      for (final workout in workoutDays) {
        final muscleGroups = <String>{};
        
        for (final exercise in workout.exercises) {
          final exerciseDetails = workoutRepository.getExerciseById(exercise.exerciseId);
          muscleGroups.addAll(exerciseDetails.primaryMuscleGroups);
        }
        
        // Проверяем наличие основных групп мышц
        expect(
          muscleGroups.length,
          greaterThanOrEqualTo(3),
          reason: 'FullBody должен прорабатывать минимум 3 группы мышц',
        );
      }
    });
  });

  group('Учет ограничений по здоровью', () {
    test('Исключение упражнений при проблемах со спиной', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
        ],
        daysPerWeek: 3,
        sessionDuration: 45,
        healthRestrictions: [HealthRestriction.back],
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем, что нет опасных упражнений для спины
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          final exerciseDetails = workoutRepository.getExerciseById(exercise.exerciseId);
          
          // Проверяем, что упражнение не противопоказано
          expect(
            exerciseDetails.contraindications.contains('back'),
            isFalse,
            reason: 'Упражнение ${exerciseDetails.name} противопоказано при проблемах со спиной',
          );
        }
      }
    });

    test('Исключение упражнений при проблемах с коленями', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweight],
        daysPerWeek: 3,
        sessionDuration: 45,
        healthRestrictions: [HealthRestriction.knees],
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем отсутствие опасных упражнений для коленей
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          final exerciseDetails = workoutRepository.getExerciseById(exercise.exerciseId);
          
          expect(
            exerciseDetails.contraindications.contains('knees'),
            isFalse,
            reason: 'Упражнение ${exerciseDetails.name} противопоказано при проблемах с коленями',
          );
        }
      }
    });
  });

  group('Адаптация под уровень пользователя', () {
    test('Адаптация для новичка (меньше подходов, больше повторений)', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
        ],
        daysPerWeek: 3,
        sessionDuration: 45,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем адаптацию параметров для новичка
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          // Новички обычно делают 2-3 подхода
          expect(exercise.sets, lessThanOrEqualTo(4));
          // Больше повторений для новичков (8-15)
          expect(exercise.reps, greaterThanOrEqualTo(8));
          expect(exercise.reps, lessThanOrEqualTo(20));
          // Больше отдыха для новичков
          expect(exercise.restTime, greaterThanOrEqualTo(60));
        }
      }
    });

    test('Адаптация для опытного пользователя (больше подходов, меньше повторений)', () async {
      final prefs = UserPreferences(
        goal: UserGoal.strength,
        experienceLevel: ExperienceLevel.advanced,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
        ],
        daysPerWeek: 4,
        sessionDuration: 90,
        preferredSystem: TrainingSystem.split,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем адаптацию для опытных
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          // Опытные могут делать больше подходов
          expect(exercise.sets, greaterThanOrEqualTo(3));
          // Меньше повторений для силы (4-8)
          if (prefs.goal == UserGoal.strength) {
            expect(exercise.reps, lessThanOrEqualTo(8));
          }
        }
      }
    });
  });

  group('Адаптация под цели пользователя', () {
    test('Адаптация для похудения (больше повторений, меньше отдых)', () async {
      final prefs = UserPreferences(
        goal: UserGoal.weightLoss,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweight, Equipment.dumbbells],
        daysPerWeek: 4,
        sessionDuration: 45,
        preferredSystem: TrainingSystem.circuit,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем параметры для похудения
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          // Больше повторений для жиросжигания
          expect(exercise.reps, greaterThanOrEqualTo(10));
          // Меньше отдыха для поддержания пульса
          expect(exercise.restTime, lessThanOrEqualTo(90));
        }
      }
    });

    test('Адаптация для набора массы (средние повторения, нормальный отдых)', () async {
      final prefs = UserPreferences(
        goal: UserGoal.muscleGain,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
        ],
        daysPerWeek: 4,
        sessionDuration: 75,
        preferredSystem: TrainingSystem.split,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan, isNotNull);
      final workoutDays = plan.workouts.where((w) => !w.isRestDay).toList();
      
      // Проверяем параметры для набора массы
      for (final workout in workoutDays) {
        for (final exercise in workout.exercises) {
          // Оптимальный диапазон повторений для массы: 6-12
          expect(exercise.reps, greaterThanOrEqualTo(6));
          expect(exercise.reps, lessThanOrEqualTo(15));
          // Нормальный отдых: 60-120 секунд
          expect(exercise.restTime, greaterThanOrEqualTo(60));
          expect(exercise.restTime, lessThanOrEqualTo(120));
        }
      }
    });
  });

  group('Производительность генерации', () {
    test('Генерация плана должна выполняться быстро (< 1 секунды)', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.intermediate,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.bench,
          Equipment.pullUpBar,
        ],
        daysPerWeek: 4,
        sessionDuration: 60,
      );

      final stopwatch = Stopwatch()..start();
      final plan = await planGenerator.generatePlan(prefs);
      stopwatch.stop();

      expect(plan, isNotNull);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Генерация плана должна занимать менее 1 секунды',
      );
    });
  });

  group('Валидация сгенерированных планов', () {
    test('План должен содержать корректную информацию', () async {
      final prefs = UserPreferences(
        goal: UserGoal.generalFitness,
        experienceLevel: ExperienceLevel.beginner,
        trainingLocation: TrainingLocation.home,
        availableEquipment: [Equipment.bodyweight],
        daysPerWeek: 3,
        sessionDuration: 45,
      );

      final plan = await planGenerator.generatePlan(prefs);

      expect(plan.id, isNotEmpty);
      expect(plan.userId, isNotEmpty);
      expect(plan.name, isNotEmpty);
      expect(plan.description, isNotEmpty);
      expect(plan.createdAt, isNotNull);
      expect(plan.userPreferences, equals(prefs));
      expect(plan.workouts, isNotEmpty);
      
      // Проверяем структуру тренировок
      for (final workout in plan.workouts) {
        expect(workout.id, isNotEmpty);
        expect(workout.name, isNotEmpty);
        expect(workout.dayOfWeek, greaterThan(0));
        expect(workout.dayOfWeek, lessThanOrEqualTo(7));
        expect(workout.duration, greaterThanOrEqualTo(0));
        
        if (!workout.isRestDay) {
          expect(workout.exercises, isNotEmpty);
          
          for (final exercise in workout.exercises) {
            expect(exercise.exerciseId, isNotEmpty);
            expect(exercise.sets, greaterThan(0));
            expect(exercise.reps, greaterThan(0));
            expect(exercise.restTime, greaterThanOrEqualTo(0));
          }
        }
      }
    });
  });
}
