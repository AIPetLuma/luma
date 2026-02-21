import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';
import 'core/services/fcm_service.dart';
import 'data/remote/analytics_client.dart';
import 'data/remote/backup_service.dart';
import 'data/remote/supabase_client_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — requires platform-specific config files:
  //   Android: android/app/google-services.json
  //   iOS:     ios/Runner/GoogleService-Info.plist
  // If config files are missing, Firebase init will fail gracefully
  // and the app will continue without push notifications.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    debugPrint('Firebase init skipped (no platform config).');
  }

  // Mixpanel analytics — token from compile-time env.
  const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');
  await AnalyticsClient.instance.init(mixpanelToken);

  // Supabase cloud backup (optional) — credentials from compile-time env.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  await SupabaseClientService.instance.init(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  await BackupService.instance.init();

  // FCM remote push (optional) — only when Firebase is configured.
  if (firebaseReady) {
    await FcmService.instance.init();
  }

  // Initialise local notifications (permission request on first launch).
  await NotificationService.init();

  // Register background task for offline pet simulation.
  await BackgroundService.init();

  runApp(const ProviderScope(child: LumaApp()));
}
