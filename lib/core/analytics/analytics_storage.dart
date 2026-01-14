// lib/core/analytics/analytics_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище для аналитических данных
class AnalyticsStorage {
  static const String _keyMetrics = 'analytics_metrics';
  static const String _keyFeedback = 'analytics_feedback';

  /// Загрузить метрики
  Future<Map<String, dynamic>> loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsJson = prefs.getString(_keyMetrics);
      
      if (metricsJson != null) {
        return Map<String, dynamic>.from(jsonDecode(metricsJson));
      }
    } catch (e) {
      print('Ошибка при загрузке метрик: $e');
    }
    
    return {};
  }

  /// Сохранить метрики
  Future<void> saveMetrics(Map<String, dynamic> metrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyMetrics, jsonEncode(metrics));
    } catch (e) {
      print('Ошибка при сохранении метрик: $e');
    }
  }

  /// Очистить все данные
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyMetrics);
      await prefs.remove(_keyFeedback);
    } catch (e) {
      print('Ошибка при очистке аналитики: $e');
    }
  }
}
