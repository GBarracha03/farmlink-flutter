import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:projeto/src/notifications/notification_item.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<NotificationItem> _notifications = [];

  bool _isInitialized = false;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  Future<void> initNotification() async {
    if (_isInitialized) return;

    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/icon_not',
    );
    const initSettings = InitializationSettings(android: initSettingsAndroid);
    await notificationsPlugin.initialize(initSettings);
    await _createNotificationChannel();

    _isInitialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_channel_id',
      'Daily Notifications',
      description: 'Daily Notification Channel',
      importance: Importance.max,
      showBadge: true,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    debugPrint('SHOW Notification: $title');

    final item = NotificationItem(
      title: title,
      message: body,
      date: DateTime.now(),
    );

    _addNotificationSafely(item);

    const androidDetails = AndroidNotificationDetails(
      'daily_channel_id',
      'Daily Notifications',
      channelDescription: 'Daily Notification Channel',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await notificationsPlugin.show(id, title, body, notificationDetails);
  }

  void _addNotificationSafely(NotificationItem item) {
    final exists = _notifications.any(
      (n) =>
          n.title == item.title &&
          n.message == item.message &&
          (n.date.difference(item.date).inSeconds.abs() < 5),
    );

    if (!exists) {
      _notifications.insert(0, item);
      notifyListeners();
    }
  }

  void removeNotificationAt(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
