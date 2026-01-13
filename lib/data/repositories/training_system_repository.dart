// lib/data/repositories/training_system_repository.dart
import 'package:fitplan_creator/data/models/training_system.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';

class TrainingSystemRepository {
  // Приватный конструктор для синглтона
  TrainingSystemRepository._privateConstructor();
  
  static final TrainingSystemRepository _instance = TrainingSystemRepository._privateConstructor();
  
  factory TrainingSystemRepository() {
    return _instance;
  }

  // База шаблонов тренировочных систем
  final List<TrainingSystemTemplate> _systemTemplates = [
    // ==================== ФУЛБАДИ (Full Body) ====================
    TrainingSystemTemplate(
      system: TrainingSystem.fullBody,
      name: 'Фулбади (Full Body)',
      description: 'На каждой тренировке прорабатываются все основные группы мышц. '
          'Идеально для начинающих и для тех, кто тренируется 2-3 раза в неделю.',
      targetAudience: 'Начинающие, средний уровень, эндоморфы на сушке',
      primaryGoal: UserGoal.generalFitness,
      compatibleGoals: [
        UserGoal.weightLoss,
        UserGoal.muscleGain,
        UserGoal.endurance,
        UserGoal.strength,
      ],
      minExperienceLevel: ExperienceLevel.beginner,
      compatibleLevels: ExperienceLevel.values,
      recommendedBodyType: null, // Универсально
      recommendedDaysPerWeek: 3,
      recommendedSessionDuration: 60,
      recommendedLocation: TrainingLocation.gym,
      requiredEquipment: [
        Equipment.barbell,
        Equipment.dumbbells,
        Equipment.bench,
        Equipment.pullUpBar,
      ],
      weeklyStructure: {
        1: WorkoutDayTemplate(
          dayNumber: 1,
          focus: 'Full Body A',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_01', sets: 3, reps: 10), // Приседания
            ExerciseTemplate(exerciseId: 'chest_01', sets: 3, reps: 10), // Отжимания
            ExerciseTemplate(exerciseId: 'back_01', sets: 3, reps: 8), // Подтягивания
            ExerciseTemplate(exerciseId: 'shoulders_01', sets: 3, reps: 10), // Жим гантелей
            ExerciseTemplate(exerciseId: 'abs_01', sets: 3, reps: 15), // Скручивания
          ],
        ),
        2: WorkoutDayTemplate(dayNumber: 2, focus: 'Rest', exercises: [], isRestDay: true),
        3: WorkoutDayTemplate(
          dayNumber: 3,
          focus: 'Full Body B',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_04', sets: 3, reps: 8), // Становая тяга
            ExerciseTemplate(exerciseId: 'chest_07', sets: 3, reps: 10), // Жим гантелей
            ExerciseTemplate(exerciseId: 'back_04', sets: 3, reps: 10), // Тяга гантели
            ExerciseTemplate(exerciseId: 'arms_01', sets: 3, reps: 12), // Подъем гантелей
            ExerciseTemplate(exerciseId: 'abs_02', sets: 3, reps: 45), // Планка
          ],
        ),
        4: WorkoutDayTemplate(dayNumber: 4, focus: 'Rest', exercises: [], isRestDay: true),
        5: WorkoutDayTemplate(
          dayNumber: 5,
          focus: 'Full Body C',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_03', sets: 3, reps: 12), // Приседания с гантелями
            ExerciseTemplate(exerciseId: 'chest_02', sets: 3, reps: 12), // Отжимания с колен
            ExerciseTemplate(exerciseId: 'back_03', sets: 3, reps: 10), // Австралийские подтягивания
            ExerciseTemplate(exerciseId: 'shoulders_02', sets: 3, reps: 15), // Махи гантелями
            ExerciseTemplate(exerciseId: 'abs_03', sets: 3, reps: 15), // Подъем ног
          ],
        ),
        6: WorkoutDayTemplate(dayNumber: 6, focus: 'Rest', exercises: [], isRestDay: true),
        7: WorkoutDayTemplate(dayNumber: 7, focus: 'Rest', exercises: [], isRestDay: true),
      },
      progressionRules: {
        'weight': 'Увеличивать вес на 2.5-5% каждую неделю',
        'reps': 'Достигнуть 12 повторений во всех подходах, затем увеличить вес',
        'frequency': '3 раза в неделю',
      },
      adaptationRules: {
        'beginner': 'Уменьшить вес на 20%, увеличить отдых между подходами',
        'home': 'Заменить упражнения на bodyweight alternatives',
        'time_constrained': 'Уменьшить количество упражнений до 4, сохраняя баланс',
      },
      priority: 8,
    ),

    // ==================== СПЛИТ (Split) ====================
    TrainingSystemTemplate(
      system: TrainingSystem.split,
      name: 'Сплит (Split)',
      description: 'Разделение тренировок по группам мышц. '
          'Позволяет глубоко проработать каждую мышечную группу.',
      targetAudience: 'Средний и опытный уровень, мезоморфы, эктоморфы',
      primaryGoal: UserGoal.muscleGain,
      compatibleGoals: [UserGoal.strength, UserGoal.generalFitness],
      minExperienceLevel: ExperienceLevel.intermediate,
      compatibleLevels: [ExperienceLevel.intermediate, ExperienceLevel.advanced],
      recommendedBodyType: BodyType.mesomorph,
      recommendedDaysPerWeek: 4,
      recommendedSessionDuration: 75,
      recommendedLocation: TrainingLocation.gym,
      requiredEquipment: [
        Equipment.barbell,
        Equipment.dumbbells,
        Equipment.bench,
        Equipment.cableMachine,
        Equipment.pullUpBar,
      ],
      weeklyStructure: {
        1: WorkoutDayTemplate(
          dayNumber: 1,
          focus: 'Грудь + Трицепс',
          exercises: [
            ExerciseTemplate(exerciseId: 'chest_12', sets: 4, reps: 8), // Жим штанги
            ExerciseTemplate(exerciseId: 'chest_08', sets: 3, reps: 12), // Разведение гантелей
            ExerciseTemplate(exerciseId: 'chest_14', sets: 3, reps: 15), // Сведение в тренажере
            ExerciseTemplate(exerciseId: 'arms_05', sets: 3, reps: 10), // Французский жим
            ExerciseTemplate(exerciseId: 'arms_06', sets: 3, reps: 12), // Разгибания на блоке
          ],
        ),
        2: WorkoutDayTemplate(
          dayNumber: 2,
          focus: 'Спина + Бицепс',
          exercises: [
            ExerciseTemplate(exerciseId: 'back_05', sets: 4, reps: 8), // Тяга штанги
            ExerciseTemplate(exerciseId: 'back_01', sets: 3, reps: 8), // Подтягивания
            ExerciseTemplate(exerciseId: 'back_06', sets: 3, reps: 12), // Горизонтальная тяга
            ExerciseTemplate(exerciseId: 'arms_01', sets: 3, reps: 10), // Подъем гантелей
            ExerciseTemplate(exerciseId: 'arms_03', sets: 3, reps: 12), // Концентрированные сгибания
          ],
        ),
        3: WorkoutDayTemplate(dayNumber: 3, focus: 'Rest', exercises: [], isRestDay: true),
        4: WorkoutDayTemplate(
          dayNumber: 4,
          focus: 'Ноги + Плечи',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_01', sets: 4, reps: 10), // Приседания
            ExerciseTemplate(exerciseId: 'legs_04', sets: 3, reps: 8), // Становая тяга
            ExerciseTemplate(exerciseId: 'legs_05', sets: 3, reps: 12), // Жим ногами
            ExerciseTemplate(exerciseId: 'shoulders_01', sets: 4, reps: 10), // Жим гантелей
            ExerciseTemplate(exerciseId: 'shoulders_02', sets: 3, reps: 15), // Махи в стороны
            ExerciseTemplate(exerciseId: 'shoulders_04', sets: 3, reps: 12), // Разведение в наклоне
          ],
        ),
        5: WorkoutDayTemplate(dayNumber: 5, focus: 'Rest', exercises: [], isRestDay: true),
        6: WorkoutDayTemplate(
          dayNumber: 6,
          focus: 'Пресс + Кардио',
          exercises: [
            ExerciseTemplate(exerciseId: 'abs_01', sets: 4, reps: 20), // Скручивания
            ExerciseTemplate(exerciseId: 'abs_03', sets: 3, reps: 15), // Подъем ног
            ExerciseTemplate(exerciseId: 'abs_05', sets: 3, reps: 20), // Велосипед
            ExerciseTemplate(exerciseId: 'cardio_02', sets: 1, reps: 20), // Скакалка
            ExerciseTemplate(exerciseId: 'cardio_08', sets: 3, reps: 30), // Скалолаз
          ],
        ),
        7: WorkoutDayTemplate(dayNumber: 7, focus: 'Rest', exercises: [], isRestDay: true),
      },
      progressionRules: {
        'weight': 'Увеличивать вес раз в 2 недели',
        'volume': 'Добавлять по 1 подходу каждую неделю',
        'intensity': 'Использовать дроп-сеты на последней неделе месяца',
      },
      priority: 7,
    ),

    // ==================== PPL (Push-Pull-Legs) ====================
    TrainingSystemTemplate(
      system: TrainingSystem.ppl,
      name: 'PPL (Push-Pull-Legs)',
      description: 'Толчок (грудь, плечи, трицепс), Тяга (спина, бицепс), Ноги. '
          'Высокая частота тренировок для максимального роста.',
      targetAudience: 'Средний и опытный уровень, набор массы',
      primaryGoal: UserGoal.muscleGain,
      compatibleGoals: [UserGoal.strength],
      minExperienceLevel: ExperienceLevel.intermediate,
      compatibleLevels: [ExperienceLevel.intermediate, ExperienceLevel.advanced],
      recommendedBodyType: BodyType.mesomorph,
      recommendedDaysPerWeek: 6,
      recommendedSessionDuration: 70,
      recommendedLocation: TrainingLocation.gym,
      requiredEquipment: [
        Equipment.barbell,
        Equipment.dumbbells,
        Equipment.bench,
        Equipment.pullUpBar,
        Equipment.parallelBars,
        Equipment.cableMachine,
      ],
      weeklyStructure: {
        1: WorkoutDayTemplate(
          dayNumber: 1,
          focus: 'Push (Толчок)',
          exercises: [
            ExerciseTemplate(exerciseId: 'chest_12', sets: 4, reps: 8), // Жим штанги
            ExerciseTemplate(exerciseId: 'shoulders_05', sets: 3, reps: 8), // Жим штанги стоя
            ExerciseTemplate(exerciseId: 'chest_08', sets: 3, reps: 12), // Разведение гантелей
            ExerciseTemplate(exerciseId: 'shoulders_02', sets: 3, reps: 15), // Махи в стороны
            ExerciseTemplate(exerciseId: 'arms_05', sets: 3, reps: 10), // Французский жим
          ],
        ),
        2: WorkoutDayTemplate(
          dayNumber: 2,
          focus: 'Pull (Тяга)',
          exercises: [
            ExerciseTemplate(exerciseId: 'back_10', sets: 3, reps: 5), // Становая тяга
            ExerciseTemplate(exerciseId: 'back_01', sets: 4, reps: 8), // Подтягивания
            ExerciseTemplate(exerciseId: 'back_04', sets: 3, reps: 10), // Тяга гантели
            ExerciseTemplate(exerciseId: 'arms_07', sets: 3, reps: 10), // Подъем штанги
            ExerciseTemplate(exerciseId: 'arms_09', sets: 3, reps: 12), // Сгибания Зоттмана
          ],
        ),
        3: WorkoutDayTemplate(
          dayNumber: 3,
          focus: 'Legs (Ноги)',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_01', sets: 4, reps: 8), // Приседания
            ExerciseTemplate(exerciseId: 'legs_05', sets: 3, reps: 10), // Жим ногами
            ExerciseTemplate(exerciseId: 'legs_07', sets: 3, reps: 12), // Сгибания ног
            ExerciseTemplate(exerciseId: 'legs_08', sets: 4, reps: 20), // Подъемы на носки
            ExerciseTemplate(exerciseId: 'abs_02', sets: 3, reps: 60), // Планка
          ],
        ),
        4: WorkoutDayTemplate(
          dayNumber: 4,
          focus: 'Push (Толчок)',
          exercises: [
            ExerciseTemplate(exerciseId: 'chest_13', sets: 4, reps: 8), // Жим на наклонной
            ExerciseTemplate(exerciseId: 'shoulders_01', sets: 3, reps: 10), // Жим гантелей
            ExerciseTemplate(exerciseId: 'chest_15', sets: 3, reps: 6), // Отжимания с хлопком
            ExerciseTemplate(exerciseId: 'shoulders_04', sets: 3, reps: 12), // Разведение в наклоне
            ExerciseTemplate(exerciseId: 'arms_06', sets: 3, reps: 15), // Разгибания на блоке
          ],
        ),
        5: WorkoutDayTemplate(
          dayNumber: 5,
          focus: 'Pull (Тяга)',
          exercises: [
            ExerciseTemplate(exerciseId: 'back_11', sets: 4, reps: 8), // Тяга Т-грифа
            ExerciseTemplate(exerciseId: 'back_02', sets: 3, reps: 10), // Подтягивания обратным хватом
            ExerciseTemplate(exerciseId: 'back_07', sets: 3, reps: 12), // Вертикальная тяга
            ExerciseTemplate(exerciseId: 'arms_02', sets: 3, reps: 12), // Молотковые сгибания
            ExerciseTemplate(exerciseId: 'arms_08', sets: 3, reps: 15), // Обратные отжимания
          ],
        ),
        6: WorkoutDayTemplate(
          dayNumber: 6,
          focus: 'Legs (Ноги)',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_04', sets: 3, reps: 8), // Становая на прямых ногах
            ExerciseTemplate(exerciseId: 'legs_09', sets: 3, reps: 10), // Болгарские выпады
            ExerciseTemplate(exerciseId: 'legs_06', sets: 3, reps: 15), // Разгибания ног
            ExerciseTemplate(exerciseId: 'legs_11', sets: 4, reps: 15), // Ягодичный мостик
            ExerciseTemplate(exerciseId: 'abs_04', sets: 3, reps: 20), // Русские скручивания
          ],
        ),
        7: WorkoutDayTemplate(dayNumber: 7, focus: 'Rest', exercises: [], isRestDay: true),
      },
      progressionRules: {
        'linear': 'Увеличивать вес каждую тренировку на 2.5 кг',
        'double_progression': 'Сначала увеличивать повторения, затем вес',
        'deload': 'Каждую 4-ю неделю уменьшать объем на 50%',
      },
      priority: 9,
    ),

    // ==================== ВЕРХ/НИЗ (Upper/Lower) ====================
    TrainingSystemTemplate(
      system: TrainingSystem.upperLower,
      name: 'Верх/Низ (Upper/Lower)',
      description: 'Чередование тренировок верха и низа тела. '
          'Оптимальная частота для сбалансированного развития.',
      targetAudience: 'Все уровни подготовки',
      primaryGoal: UserGoal.generalFitness,
      compatibleGoals: [
        UserGoal.muscleGain,
        UserGoal.strength,
        UserGoal.weightLoss,
        UserGoal.endurance,
      ],
      minExperienceLevel: ExperienceLevel.beginner,
      compatibleLevels: ExperienceLevel.values,
      recommendedBodyType: null, // Универсально
      recommendedDaysPerWeek: 4,
      recommendedSessionDuration: 65,
      recommendedLocation: TrainingLocation.gym,
      requiredEquipment: [
        Equipment.barbell,
        Equipment.dumbbells,
        Equipment.bench,
        Equipment.pullUpBar,
        Equipment.legPress,
      ],
      weeklyStructure: {
        1: WorkoutDayTemplate(
          dayNumber: 1,
          focus: 'Upper (Верх)',
          exercises: [
            ExerciseTemplate(exerciseId: 'chest_12', sets: 4, reps: 8), // Жим штанги
            ExerciseTemplate(exerciseId: 'back_01', sets: 3, reps: 8), // Подтягивания
            ExerciseTemplate(exerciseId: 'shoulders_01', sets: 3, reps: 10), // Жим гантелей
            ExerciseTemplate(exerciseId: 'arms_01', sets: 3, reps: 12), // Подъем гантелей
            ExerciseTemplate(exerciseId: 'arms_06', sets: 3, reps: 15), // Разгибания на блоке
          ],
        ),
        2: WorkoutDayTemplate(
          dayNumber: 2,
          focus: 'Lower (Низ)',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_01', sets: 4, reps: 8), // Приседания
            ExerciseTemplate(exerciseId: 'legs_04', sets: 3, reps: 8), // Становая на прямых ногах
            ExerciseTemplate(exerciseId: 'legs_05', sets: 3, reps: 12), // Жим ногами
            ExerciseTemplate(exerciseId: 'legs_08', sets: 4, reps: 20), // Подъемы на носки
            ExerciseTemplate(exerciseId: 'abs_01', sets: 3, reps: 20), // Скручивания
          ],
        ),
        3: WorkoutDayTemplate(dayNumber: 3, focus: 'Rest', exercises: [], isRestDay: true),
        4: WorkoutDayTemplate(
          dayNumber: 4,
          focus: 'Upper (Верх)',
          exercises: [
            ExerciseTemplate(exerciseId: 'chest_07', sets: 4, reps: 10), // Жим гантелей
            ExerciseTemplate(exerciseId: 'back_04', sets: 3, reps: 10), // Тяга гантели
            ExerciseTemplate(exerciseId: 'shoulders_02', sets: 3, reps: 15), // Махи в стороны
            ExerciseTemplate(exerciseId: 'arms_07', sets: 3, reps: 10), // Подъем штанги
            ExerciseTemplate(exerciseId: 'arms_05', sets: 3, reps: 12), // Французский жим
          ],
        ),
        5: WorkoutDayTemplate(dayNumber: 5, focus: 'Rest', exercises: [], isRestDay: true),
        6: WorkoutDayTemplate(
          dayNumber: 6,
          focus: 'Lower (Низ)',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_10', sets: 4, reps: 10), // Румынская тяга
            ExerciseTemplate(exerciseId: 'legs_09', sets: 3, reps: 10), // Болгарские выпады
            ExerciseTemplate(exerciseId: 'legs_07', sets: 3, reps: 15), // Сгибания ног
            ExerciseTemplate(exerciseId: 'legs_11', sets: 3, reps: 15), // Ягодичный мостик
            ExerciseTemplate(exerciseId: 'abs_03', sets: 3, reps: 15), // Подъем ног
          ],
        ),
        7: WorkoutDayTemplate(dayNumber: 7, focus: 'Rest', exercises: [], isRestDay: true),
      },
      progressionRules: {
        'alternating': 'Чередовать тяжелые и легкие дни',
        'weight': 'Увеличивать вес каждую неделю на 2.5%',
        'variation': 'Менять упражнения каждые 4-6 недель',
      },
      priority: 6,
    ),

    // ==================== КРУГОВАЯ ТРЕНИРОВКА (Circuit) ====================
    TrainingSystemTemplate(
      system: TrainingSystem.circuit,
      name: 'Круговая тренировка (Circuit)',
      description: 'Выполнение упражнений по кругу с минимальным отдыхом. '
          'Отлично подходит для жиросжигания и развития выносливости.',
      targetAudience: 'Все уровни, эндоморфы, ограниченное время',
      primaryGoal: UserGoal.weightLoss,
      compatibleGoals: [UserGoal.endurance, UserGoal.generalFitness],
      minExperienceLevel: ExperienceLevel.beginner,
      compatibleLevels: ExperienceLevel.values,
      recommendedBodyType: BodyType.endomorph,
      recommendedDaysPerWeek: 3,
      recommendedSessionDuration: 40,
      recommendedLocation: TrainingLocation.home,
      requiredEquipment: [Equipment.bodyweight, Equipment.dumbbells],
      weeklyStructure: {
        1: WorkoutDayTemplate(
          dayNumber: 1,
          focus: 'Full Body Circuit',
          exercises: [
            ExerciseTemplate(exerciseId: 'cardio_03', sets: 1, reps: 10, restTime: 30), // Берпи
            ExerciseTemplate(exerciseId: 'chest_01', sets: 1, reps: 15, restTime: 30), // Отжимания
            ExerciseTemplate(exerciseId: 'legs_01', sets: 1, reps: 20, restTime: 30), // Приседания
            ExerciseTemplate(exerciseId: 'back_03', sets: 1, reps: 12, restTime: 30), // Австрал. подтягивания
            ExerciseTemplate(exerciseId: 'abs_08', sets: 1, reps: 20, restTime: 30), // Альпинист
            ExerciseTemplate(exerciseId: 'cardio_09', sets: 1, reps: 30, restTime: 30), // Джампинг джек
          ],
          notes: 'Выполнить 3-4 круга с отдыхом 60 секунд между кругами',
        ),
        2: WorkoutDayTemplate(dayNumber: 2, focus: 'Active Recovery', exercises: [], isRestDay: true),
        3: WorkoutDayTemplate(
          dayNumber: 3,
          focus: 'HIIT Circuit',
          exercises: [
            ExerciseTemplate(exerciseId: 'cardio_04', sets: 1, reps: 15, restTime: 20), // Выпрыгивания
            ExerciseTemplate(exerciseId: 'chest_15', sets: 1, reps: 8, restTime: 20), // Отжимания с хлопком
            ExerciseTemplate(exerciseId: 'legs_02', sets: 1, reps: 12, restTime: 20), // Выпады
            ExerciseTemplate(exerciseId: 'arms_08', sets: 1, reps: 15, restTime: 20), // Обратные отжимания
            ExerciseTemplate(exerciseId: 'abs_05', sets: 1, reps: 20, restTime: 20), // Велосипед
            ExerciseTemplate(exerciseId: 'cardio_02', sets: 1, reps: 60, restTime: 20), // Скакалка
          ],
          notes: 'Выполнить 4-5 круга с отдыхом 45 секунд между кругами',
        ),
        4: WorkoutDayTemplate(dayNumber: 4, focus: 'Rest', exercises: [], isRestDay: true),
        5: WorkoutDayTemplate(
          dayNumber: 5,
          focus: 'Strength Circuit',
          exercises: [
            ExerciseTemplate(exerciseId: 'legs_03', sets: 3, reps: 12, restTime: 45), // Приседания с гантелями
            ExerciseTemplate(exerciseId: 'chest_07', sets: 3, reps: 10, restTime: 45), // Жим гантелей
            ExerciseTemplate(exerciseId: 'back_04', sets: 3, reps: 10, restTime: 45), // Тяга гантели
            ExerciseTemplate(exerciseId: 'shoulders_02', sets: 3, reps: 15, restTime: 45), // Махи гантелями
            ExerciseTemplate(exerciseId: 'abs_02', sets: 3, reps: 60, restTime: 45), // Планка
          ],
          notes: 'Выполнить упражнения последовательно, 3 круга',
        ),
        6: WorkoutDayTemplate(dayNumber: 6, focus: 'Active Recovery', exercises: [], isRestDay: true),
        7: WorkoutDayTemplate(dayNumber: 7, focus: 'Rest', exercises: [], isRestDay: true),
      },
      progressionRules: {
        'time': 'Уменьшать время отдыха между упражнениями',
        'circuits': 'Увеличивать количество кругов',
        'intensity': 'Добавлять веса или более сложные варианты упражнений',
      },
      priority: 5,
    ),

    // ==================== КАРДИО ТРЕНИРОВКИ ====================
    TrainingSystemTemplate(
      system: TrainingSystem.cardio,
      name: 'Кардио тренировки',
      description: 'Тренировки для укрепления сердечно-сосудистой системы, '
          'жиросжигания и улучшения выносливости.',
      targetAudience: 'Все уровни, эндоморфы, восстановление',
      primaryGoal: UserGoal.endurance,
      compatibleGoals: [UserGoal.weightLoss, UserGoal.generalFitness],
      minExperienceLevel: ExperienceLevel.beginner,
      compatibleLevels: ExperienceLevel.values,
      recommendedBodyType: BodyType.endomorph,
      recommendedDaysPerWeek: 4,
      recommendedSessionDuration: 45,
      recommendedLocation: TrainingLocation.gym,
      requiredEquipment: [Equipment.cardioEquipment, Equipment.jumpRope],
      weeklyStructure: {
        1: WorkoutDayTemplate(
          dayNumber: 1,
          focus: 'LISS Cardio',
          exercises: [
            ExerciseTemplate(exerciseId: 'cardio_02', sets: 1, reps: 30, restTime: 0), // Скакалка
            ExerciseTemplate(exerciseId: 'warmup_10', sets: 1, reps: 15, restTime: 0), // Приседания
            ExerciseTemplate(exerciseId: 'cardio_01', sets: 1, reps: 20, restTime: 0), // Бег на месте
          ],
          notes: 'Низкая интенсивность, 60-70% от максимального пульса, 30-45 минут',
        ),
        2: WorkoutDayTemplate(
          dayNumber: 2,
          focus: 'HIIT Session',
          exercises: [
            ExerciseTemplate(exerciseId: 'cardio_03', sets: 8, reps: 10, restTime: 30), // Берпи
            ExerciseTemplate(exerciseId: 'cardio_04', sets: 8, reps: 15, restTime: 30), // Выпрыгивания
            ExerciseTemplate(exerciseId: 'cardio_08', sets: 8, reps: 30, restTime: 30), // Скалолаз
            ExerciseTemplate(exerciseId: 'cardio_09', sets: 8, reps: 30, restTime: 30), // Джампинг джек
          ],
          notes: '20 секунд работа, 10 секунд отдых, 8 кругов каждого упражнения',
        ),
        3: WorkoutDayTemplate(dayNumber: 3, focus: 'Active Recovery', exercises: [], isRestDay: true),
        4: WorkoutDayTemplate(
          dayNumber: 4,
          focus: 'Steady State',
          exercises: [
            ExerciseTemplate(exerciseId: 'warmup_01', sets: 1, reps: 10, restTime: 0), // Разминка
            ExerciseTemplate(exerciseId: 'cardio_01', sets: 1, reps: 40, restTime: 0), // Бег на месте
            ExerciseTemplate(exerciseId: 'cooldown_01', sets: 1, reps: 30, restTime: 0), // Растяжка
          ],
          notes: 'Умеренная интенсивность, 40 минут непрерывно',
        ),
        5: WorkoutDayTemplate(
          dayNumber: 5,
          focus: 'Interval Training',
          exercises: [
            ExerciseTemplate(exerciseId: 'cardio_06', sets: 10, reps: 20, restTime: 60), // Забегания
            ExerciseTemplate(exerciseId: 'cardio_07', sets: 10, reps: 20, restTime: 60), // Прыжки в стороны
          ],
          notes: '30 секунд максимальной интенсивности, 60 секунд отдыха, 10 интервалов',
        ),
        6: WorkoutDayTemplate(dayNumber: 6, focus: 'Rest', exercises: [], isRestDay: true),
        7: WorkoutDayTemplate(dayNumber: 7, focus: 'Active Recovery', exercises: [], isRestDay: true),
      },
      progressionRules: {
        'duration': 'Увеличивать продолжительность на 10% в неделю',
        'intensity': 'Увеличивать интенсивность или уменьшать отдых',
        'frequency': 'Добавлять еще один день кардио',
      },
      priority: 4,
    ),
  ];

  // Получить все системы тренировок
  List<TrainingSystemTemplate> getAllSystems() {
    return List.unmodifiable(_systemTemplates);
  }

  // Получить систему по типу
  TrainingSystemTemplate? getSystemByType(TrainingSystem system) {
    try {
      return _systemTemplates.firstWhere((template) => template.system == system);
    } catch (e) {
      return null;
    }
  }

  // Получить рекомендованные системы для пользователя
  List<TrainingSystemTemplate> getRecommendedSystems(UserPreferences prefs) {
    final compatibleSystems = _systemTemplates
        .where((system) => system.isCompatibleWith(prefs))
        .toList();

    // Сортировка по приоритету (высокий приоритет = более подходящая система)
    compatibleSystems.sort((a, b) => b.priority.compareTo(a.priority));

    return compatibleSystems;
  }

  // Получить лучшую систему для пользователя
  TrainingSystemTemplate? getBestSystemForUser(UserPreferences prefs) {
    final recommended = getRecommendedSystems(prefs);
    return recommended.isNotEmpty ? recommended.first : null;
  }

  // Адаптировать систему под пользователя
  TrainingSystemTemplate adaptSystemForUser(
    TrainingSystemTemplate system,
    UserPreferences prefs,
  ) {
    return system.adaptToUser(prefs);
  }

  // Получить системы по цели
  List<TrainingSystemTemplate> getSystemsByGoal(UserGoal goal) {
    return _systemTemplates
        .where((system) => 
            system.primaryGoal == goal || system.compatibleGoals.contains(goal))
        .toList();
  }

  // Получить системы по уровню опыта
  List<TrainingSystemTemplate> getSystemsByExperience(ExperienceLevel level) {
    return _systemTemplates
        .where((system) => system.compatibleLevels.contains(level))
        .toList();
  }

  // Получить системы по месту тренировок
  List<TrainingSystemTemplate> getSystemsByLocation(TrainingLocation location) {
    return _systemTemplates
        .where((system) => system.recommendedLocation == location)
        .toList();
  }

  // Поиск систем по ключевым словам
  List<TrainingSystemTemplate> searchSystems(String query) {
    if (query.isEmpty) return _systemTemplates;
    
    final lowerQuery = query.toLowerCase();
    return _systemTemplates.where((system) {
      return system.name.toLowerCase().contains(lowerQuery) ||
             system.description.toLowerCase().contains(lowerQuery) ||
             system.targetAudience.toLowerCase().contains(lowerQuery) ||
             system.primaryGoal.displayName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Статистика по системам тренировок
  Map<String, dynamic> getStatistics() {
    return {
      'totalSystems': _systemTemplates.length,
      'byType': {
        for (var system in TrainingSystem.values)
          system.name: _systemTemplates
              .where((t) => t.system == system)
              .length,
      },
      'byGoal': {
        for (var goal in UserGoal.values)
          goal.name: getSystemsByGoal(goal).length,
      },
      'byExperience': {
        for (var level in ExperienceLevel.values)
          level.name: getSystemsByExperience(level).length,
      },
      'byLocation': {
        for (var location in TrainingLocation.values)
          location.name: getSystemsByLocation(location).length,
      },
    };
  }

  // Создать план тренировок из системы
  Future<List<WorkoutDayTemplate>> createWorkoutPlan(
    TrainingSystemTemplate system,
    UserPreferences prefs,
  ) async {
    // Адаптируем систему под пользователя
    final adaptedSystem = adaptSystemForUser(system, prefs);
    
    // Адаптируем каждое упражнение под уровень пользователя
    final adaptedDays = adaptedSystem.weeklyStructure.entries.map((entry) {
      final day = entry.value;
      final adaptedExercises = day.exercises
          .map((exercise) => exercise.adaptToLevel(prefs.experienceLevel ?? ExperienceLevel.beginner))
          .toList();
      
      return day.copyWith(exercises: adaptedExercises);
    }).toList();
    
    return adaptedDays;
  }
}