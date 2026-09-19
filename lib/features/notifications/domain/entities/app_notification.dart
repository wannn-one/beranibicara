import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final int id;
  final String title;
  final String body;
  final String? type;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String? route;
  final DateTime sentAt;
  final DateTime? readAt;

  const AppNotification({
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

  bool get isUnread => readAt == null;

  @override
  List<Object?> get props => [id, readAt, sentAt];
}
