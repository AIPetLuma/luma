import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages local notification setup and display.
///
/// Firebase Cloud Messaging handles remote push; this service handles
/// locally-triggered notifications (pet reaching out, diary ready, etc.)
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialised = false;

  /// Initialise the local notification plugin. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialised) return;

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    // Request permission on iOS / Android 13+.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialised = true;
  }

  /// Show a pet-initiated notification.
  static Future<void> showPetMessage({
    required String title,
    required String body,
  }) async {
    await init(); // ensure initialised

    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'luma_pet',
          'Pet Messages',
          channelDescription: 'Your Luma pet reaching out to you',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
