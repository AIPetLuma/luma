import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise local notifications (permission request on first launch).
  await NotificationService.init();

  // Register background task for offline pet simulation.
  await BackgroundService.init();

  // Firebase setup requires platform-specific config files:
  //   Android: android/app/google-services.json
  //   iOS:     ios/Runner/GoogleService-Info.plist
  // Uncomment after adding those files:
  // await Firebase.initializeApp();

  runApp(const ProviderScope(child: LumaApp()));
}
