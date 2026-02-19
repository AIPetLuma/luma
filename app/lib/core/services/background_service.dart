import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/local/pet_dao.dart';
import '../engine/need_system.dart';
import '../engine/time_simulator.dart';

/// Background task identifier.
const kBackgroundTaskName = 'luma_background_tick';

/// WorkManager callback — runs in its own isolate.
///
/// Loads the pet from DB, simulates elapsed time, and fires a local
/// notification if the pet's loneliness exceeds the push threshold.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != kBackgroundTaskName) return true;

    final petDao = PetDao();
    final pet = await petDao.load();
    if (pet == null) return true;

    // Simulate elapsed time.
    final elapsed = pet.minutesSinceLastActive;
    if (elapsed < 5) return true; // Too recent, skip.

    final simulator = TimeSimulator();
    final result = simulator.simulate(pet, elapsed);

    // Check if the pet should reach out.
    final needSystem = NeedSystem();
    if (needSystem.shouldReachOut(result.state.needs)) {
      await _showNotification(result.state.name, result.state.emotion.label);
    }

    // Persist updated state.
    await petDao.update(result.state);

    return true;
  });
}

Future<void> _showNotification(String petName, String mood) async {
  final notifications = FlutterLocalNotificationsPlugin();

  // Ensure initialised (idempotent).
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final message = switch (mood) {
    'melancholy' => '$petName is feeling a bit down and misses you.',
    'anxious' => '$petName seems worried. Maybe check in?',
    'withdrawn' => '$petName has been quiet for a while...',
    _ => '$petName is thinking about you!',
  };

  await notifications.show(
    0, // single notification, replaced on repeat
    petName,
    message,
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

/// Register the background task. Call once from main().
class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'luma-bg-tick',
      kBackgroundTaskName,
      frequency: const Duration(minutes: 15), // minimum on Android
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
