// lib/core/analytics/analytics_event.dart
/// Базовый класс для событий аналитики
abstract class AnalyticsEvent {
  final DateTime timestamp;
  final String eventType;

  AnalyticsEvent({
    DateTime? timestamp,
    required this.eventType,
  }) : timestamp = timestamp ?? DateTime.now();
}
