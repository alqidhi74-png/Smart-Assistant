import 'package:flutter/foundation.dart';

enum NotificationType { success, info, warning }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = NotificationType.info,
    this.isRead = false,
  });
}

class NotificationStore {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  final ValueNotifier<List<AppNotification>> notifications = ValueNotifier([]);
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  void addNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.info,
  }) {
    final newNotif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );
    notifications.value = [newNotif, ...notifications.value];
    _updateUnreadCount();
  }

  void markAllAsRead() {
    for (var n in notifications.value) {
      n.isRead = true;
    }
    _updateUnreadCount();
    // Trigger notification list update
    notifications.value = [...notifications.value];
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.value.where((n) => !n.isRead).length;
  }

  void clearAll() {
    notifications.value = [];
    unreadCount.value = 0;
  }
}
