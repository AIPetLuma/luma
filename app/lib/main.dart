import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';
import 'data/remote/analytics_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — requires platform-specific config files:
  //   Android: android/app/google-services.json
  //   iOS:     ios/Runner/GoogleService-Info.plist
  // If config files are missing, Firebase init will fail gracefully
  // and the app will continue without push notifications.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config not yet available — local-only mode.
    debugPrint('Firebase init skipped (no platform config).');
  }

  // Mixpanel analytics — token from compile-time env.
  // Pass MIXPANEL_TOKEN via --dart-define when building.
  // Empty token → stub mode (no events sent).
  const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
  await AnalyticsClient.instance.init(mixpanelToken);

  // Initialise local notifications (permission request on first launch).
  await NotificationService.init();

  // Register background task for offline pet simulation.
  await BackgroundService.init();

  runApp(const ProviderScope(child: LumaApp()));
}
