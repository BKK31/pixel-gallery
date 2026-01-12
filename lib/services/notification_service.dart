import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showIndexingProgress(int current, int total) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'indexing_channel',
      'Media Indexing',
      channelDescription: 'Shows progress of media library indexing',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: total,
      progress: current,
      onlyAlertOnce: true,
      ongoing: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      'Indexing Gallery',
      'Scanning $current of $total items...',
      notificationDetails,
    );
  }

  Future<void> dismissIndexingProgress() async {
    await _notifications.cancel(1);
  }

  Future<void> showCatalogingProgress(int current, int total) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'cataloging_channel',
      'Media Cataloging',
      channelDescription: 'Shows progress of deep metadata extraction',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: total,
      progress: current,
      onlyAlertOnce: true,
      ongoing: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      2,
      'Cataloging Gallery',
      'Processing $current of $total items...',
      notificationDetails,
    );
  }

  Future<void> dismissCatalogingProgress() async {
    await _notifications.cancel(2);
  }
}
