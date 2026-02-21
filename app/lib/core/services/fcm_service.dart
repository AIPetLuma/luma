import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/remote/push_token_service.dart';
import 'notification_service.dart';

/// Remote push messaging integration.
///
/// Local notifications remain enabled for offline/background reach-out.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  FirebaseMessaging? _messaging;

  bool _initialised = false;
  bool _firebaseUnavailableLogged = false;
  String? _token;
  String? _boundPetId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  Future<void> init() async {
    if (_initialised) return;
    final messaging = _resolveMessaging();
    if (messaging == null) return;

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _token = await messaging.getToken();

      _tokenRefreshSub = messaging.onTokenRefresh.listen((token) {
        _token = token;
        final petId = _boundPetId;
        if (petId != null) {
          unawaited(_syncToken(petId));
        }
      });

      _foregroundMessageSub = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      _initialised = true;
    } catch (e) {
      debugPrint('FcmService: init failed ($e).');
    }
  }

  Future<void> bindPet(String petId) async {
    _boundPetId = petId;

    if (!_initialised) {
      await init();
    }

    if (!_initialised) return;
    await _syncToken(petId);
  }

  Future<void> _syncToken(String petId) async {
    final messaging = _resolveMessaging();
    if (messaging == null) return;

    final token = _token ?? await messaging.getToken();
    if (token == null || token.isEmpty) return;

    _token = token;

    await PushTokenService.instance.upsertToken(
      petId: petId,
      token: token,
      platform: _platformName(),
      locale: WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Luma';
    final body = message.notification?.body ?? 'You have a new message.';

    unawaited(NotificationService.showPetMessage(title: title, body: body));
  }

  String _platformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  FirebaseMessaging? _resolveMessaging() {
    if (_messaging != null) return _messaging;

    try {
      if (Firebase.apps.isEmpty) {
        if (!_firebaseUnavailableLogged) {
          debugPrint('FcmService: Firebase unavailable — disabled.');
          _firebaseUnavailableLogged = true;
        }
        return null;
      }
      _messaging = FirebaseMessaging.instance;
      return _messaging;
    } catch (e) {
      if (!_firebaseUnavailableLogged) {
        debugPrint('FcmService: Firebase unavailable ($e) — disabled.');
        _firebaseUnavailableLogged = true;
      }
      return null;
    }
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundMessageSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundMessageSub = null;
    _token = null;
    _boundPetId = null;
    _initialised = false;
    _firebaseUnavailableLogged = false;
    _messaging = null;
  }
}
