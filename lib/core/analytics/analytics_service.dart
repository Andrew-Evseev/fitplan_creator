// lib/core/analytics/analytics_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fitplan_creator/data/models/user_preferences.dart';
import 'analytics_storage.dart';

/// Сервис для сбора аналитики и метрик
class AnalyticsService {
  final AnalyticsStorage _storage = AnalyticsStorage();
  
  // Счетчики метрик
  final Map<String, int> _systemUsageCounts = {};
  final Map<String, int> _exerciseReplacementCounts = {};
  final List<PlanGenerationMetric> _generationMetrics = [];
  final List<FeedbackEvent> _feedbackEvents = [];

  AnalyticsService() {
    _loadStoredData();
  }

  /// Загрузить сохраненные данные
  Future<void> _loadStoredData() async {
    try {
      final stored = await _storage.loadMetrics();
      _systemUsageCounts.addAll(stored['systemUsage'] ?? {});
      _exerciseReplacementCounts.addAll(stored['exerciseReplacements'] ?? {});
    } catch (e) {
      debugPrint('Ошибка при загрузке аналитики: $e');
    }
  }

  /// Сохранить метрики
  Future<void> _saveMetrics() async {
    try {
      await _storage.saveMetrics({
        'systemUsage': _systemUsageCounts,
        'exerciseReplacements': _exerciseReplacementCounts,
      });
    } catch (e) {
      debugPrint('Ошибка при сохранении аналитики: $e');
    }
  }

  /// Записать событие выбора системы тренировок
  void logSystemSelection(TrainingSystem system, UserPreferences prefs) {
    final key = system.displayName;
    _systemUsageCounts[key] = (_systemUsageCounts[key] ?? 0) + 1;
    _saveMetrics();
    
    debugPrint('Analytics: System selected - ${system.displayName}');
  }

  /// Записать метрику генерации плана
  void logPlanGeneration({
    required UserPreferences prefs,
    required TrainingSystem? system,
    required Duration generationTime,
    required bool success,
    String? error,
  }) {
    final metric = PlanGenerationMetric(
      timestamp: DateTime.now(),
      system: system?.displayName,
      goal: prefs.goal?.displayName,
      experienceLevel: prefs.experienceLevel?.displayName,
      daysPerWeek: prefs.daysPerWeek,
      generationTimeMs: generationTime.inMilliseconds,
      success: success,
      error: error,
    );
    
    _generationMetrics.add(metric);
    
    // Ограничиваем размер списка до 1000 записей
    if (_generationMetrics.length > 1000) {
      _generationMetrics.removeAt(0);
    }
    
    debugPrint('Analytics: Plan generated - ${system?.displayName}, time: ${generationTime.inMilliseconds}ms');
  }

  /// Записать замену упражнения
  void logExerciseReplacement(String fromExerciseId, String toExerciseId, String reason) {
    final key = '$fromExerciseId -> $toExerciseId';
    _exerciseReplacementCounts[key] = (_exerciseReplacementCounts[key] ?? 0) + 1;
    _saveMetrics();
    
    debugPrint('Analytics: Exercise replaced - $key ($reason)');
  }

  /// Записать фидбек о плане
  void logPlanFeedback({
    required String planId,
    required bool isPositive,
    String? comment,
    Map<String, dynamic>? metadata,
  }) {
    final feedback = FeedbackEvent(
      timestamp: DateTime.now(),
      planId: planId,
      isPositive: isPositive,
      comment: comment,
      metadata: metadata ?? {},
    );
    
    _feedbackEvents.add(feedback);
    
    // Ограничиваем размер до 500 записей
    if (_feedbackEvents.length > 500) {
      _feedbackEvents.removeAt(0);
    }
    
    debugPrint('Analytics: Plan feedback - planId: $planId, positive: $isPositive');
  }

  /// Записать проблему с упражнением
  void logExerciseIssue({
    required String exerciseId,
    required String issueType,
    String? description,
  }) {
    final issue = FeedbackEvent(
      timestamp: DateTime.now(),
      planId: '',
      isPositive: false,
      comment: 'Exercise issue: $issueType - $description',
      metadata: {
        'exerciseId': exerciseId,
        'issueType': issueType,
      },
    );
    
    _feedbackEvents.add(issue);
    
    debugPrint('Analytics: Exercise issue - $exerciseId: $issueType');
  }

  /// Получить статистику по системам тренировок
  Map<String, dynamic> getSystemStatistics() {
    final total = _systemUsageCounts.values.fold(0, (sum, count) => sum + count);
    
    return {
      'totalSelections': total,
      'bySystem': Map<String, int>.from(_systemUsageCounts),
      'percentages': _systemUsageCounts.map(
        (key, value) => MapEntry(key, total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0'),
      ),
    };
  }

  /// Получить статистику по заменам упражнений
  Map<String, dynamic> getExerciseReplacementStatistics() {
    final sortedReplacements = Map.fromEntries(
      _exerciseReplacementCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
    
    return {
      'totalReplacements': _exerciseReplacementCounts.values.fold(0, (sum, count) => sum + count),
      'topReplacements': sortedReplacements.entries.take(10).map((e) => {
        'replacement': e.key,
        'count': e.value,
      }).toList(),
    };
  }

  /// Получить статистику по генерации планов
  Map<String, dynamic> getGenerationStatistics() {
    if (_generationMetrics.isEmpty) {
      return {
        'totalGenerations': 0,
        'averageTimeMs': 0,
        'successRate': 0.0,
      };
    }
    
    final successful = _generationMetrics.where((m) => m.success).length;
    final totalTime = _generationMetrics.fold<int>(
      0,
      (sum, m) => sum + m.generationTimeMs,
    );
    
    return {
      'totalGenerations': _generationMetrics.length,
      'successfulGenerations': successful,
      'failedGenerations': _generationMetrics.length - successful,
      'successRate': _generationMetrics.isNotEmpty
          ? (successful / _generationMetrics.length * 100).toStringAsFixed(1)
          : '0.0',
      'averageTimeMs': (totalTime / _generationMetrics.length).round(),
      'minTimeMs': _generationMetrics.map((m) => m.generationTimeMs).reduce((a, b) => a < b ? a : b),
      'maxTimeMs': _generationMetrics.map((m) => m.generationTimeMs).reduce((a, b) => a > b ? a : b),
      'bySystem': _groupMetricsBySystem(),
      'byGoal': _groupMetricsByGoal(),
    };
  }

  /// Группировка метрик по системе
  Map<String, dynamic> _groupMetricsBySystem() {
    final bySystem = <String, List<int>>{};
    
    for (final metric in _generationMetrics) {
      if (metric.system != null) {
        bySystem.putIfAbsent(metric.system!, () => []).add(metric.generationTimeMs);
      }
    }
    
    return bySystem.map((key, times) => MapEntry(
      key,
      {
        'count': times.length,
        'averageTimeMs': times.isNotEmpty 
            ? (times.reduce((a, b) => a + b) / times.length).round()
            : 0,
      },
    ));
  }

  /// Группировка метрик по цели
  Map<String, dynamic> _groupMetricsByGoal() {
    final byGoal = <String, int>{};
    
    for (final metric in _generationMetrics) {
      if (metric.goal != null) {
        byGoal[metric.goal!] = (byGoal[metric.goal] ?? 0) + 1;
      }
    }
    
    return byGoal;
  }

  /// Получить фидбек события
  List<Map<String, dynamic>> getFeedbackEvents({int? limit}) {
    final events = limit != null
        ? _feedbackEvents.reversed.take(limit).toList()
        : _feedbackEvents.reversed.toList();
    
    return events.map((e) => {
      'timestamp': e.timestamp.toIso8601String(),
      'planId': e.planId,
      'isPositive': e.isPositive,
      'comment': e.comment,
      'metadata': e.metadata,
    }).toList();
  }

  /// Экспорт всех данных для ML
  Map<String, dynamic> exportForML() {
    return {
      'systemUsage': _systemUsageCounts,
      'exerciseReplacements': _exerciseReplacementCounts,
      'generationMetrics': _generationMetrics.map((m) => {
        'timestamp': m.timestamp.toIso8601String(),
        'system': m.system,
        'goal': m.goal,
        'experienceLevel': m.experienceLevel,
        'daysPerWeek': m.daysPerWeek,
        'generationTimeMs': m.generationTimeMs,
        'success': m.success,
        'error': m.error,
      }).toList(),
      'feedbackEvents': _feedbackEvents.map((e) => {
        'timestamp': e.timestamp.toIso8601String(),
        'planId': e.planId,
        'isPositive': e.isPositive,
        'comment': e.comment,
        'metadata': e.metadata,
      }).toList(),
    };
  }

  /// Очистить все данные
  Future<void> clearAll() async {
    _systemUsageCounts.clear();
    _exerciseReplacementCounts.clear();
    _generationMetrics.clear();
    _feedbackEvents.clear();
    await _storage.clear();
  }
}

/// Метрика генерации плана
class PlanGenerationMetric {
  final DateTime timestamp;
  final String? system;
  final String? goal;
  final String? experienceLevel;
  final int? daysPerWeek;
  final int generationTimeMs;
  final bool success;
  final String? error;

  PlanGenerationMetric({
    required this.timestamp,
    this.system,
    this.goal,
    this.experienceLevel,
    this.daysPerWeek,
    required this.generationTimeMs,
    required this.success,
    this.error,
  });
}

/// Событие фидбека
class FeedbackEvent {
  final DateTime timestamp;
  final String planId;
  final bool isPositive;
  final String? comment;
  final Map<String, dynamic> metadata;

  FeedbackEvent({
    required this.timestamp,
    required this.planId,
    required this.isPositive,
    this.comment,
    required this.metadata,
  });
}
