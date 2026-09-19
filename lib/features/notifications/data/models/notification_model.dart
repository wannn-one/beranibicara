import 'package:beranibicara/features/notifications/domain/entities/app_notification.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? type;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String? route;
  final DateTime sentAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.relatedEntityType,
    this.relatedEntityId,
    this.route,
    required this.sentAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? route;
    if (data is Map && data['route'] != null) {
      route = data['route'].toString();
    }
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['notification_type'] as String?,
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      route: route,
      sentAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      route: route,
      sentAt: sentAt,
      readAt: readAt,
    );
  }
}
