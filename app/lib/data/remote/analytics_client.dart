import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// Analytics event tracking for the 21-day retention experiment.
///
/// Events correspond to the 10 埋点 defined in
/// `p0/03_21天留存实验设计.md`.
///
/// Wraps the Mixpanel SDK. If no token is configured or initialization
/// fails, all calls are silently dropped (safe for dev/test).
class AnalyticsClient {
  Mixpanel? _mixpanel;

  AnalyticsClient._();

  /// Singleton instance.
  static final AnalyticsClient instance = AnalyticsClient._();

  /// Initialise Mixpanel with a project token.
  ///
  /// Call once at app startup. If [token] is empty or init fails,
  /// the client stays in stub mode (events are no-ops).
  Future<void> init(String token) async {
    if (token.isEmpty) {
      debugPrint('AnalyticsClient: no Mixpanel token — stub mode.');
      return;
    }
    try {
      _mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: true,
      );
      debugPrint('AnalyticsClient: Mixpanel initialised.');
    } catch (e) {
      debugPrint('AnalyticsClient: Mixpanel init failed ($e) — stub mode.');
    }
  }

  /// Identify a user (pet owner) so events are attributed correctly.
  void identify(String distinctId) {
    _mixpanel?.identify(distinctId);
  }

  // ── 10 retention experiment events ──

  void signupCompleted({required String petId}) =>
      _track('signup_completed', {'pet_id': petId});

  void sessionStarted({required String petId}) =>
      _track('session_started', {'pet_id': petId});

  void sessionEnded({required String petId, required int durationSeconds}) =>
      _track('session_ended', {
        'pet_id': petId,
        'duration_s': durationSeconds,
      });

  void aiDisclosureShown({required String location}) =>
      _track('ai_disclosure_shown', {'location': location});

  void riskSignalDetected({required int level, required String source}) =>
      _track('risk_signal_detected', {'level': level, 'source': source});

  void riskLevelAssigned({required int level}) =>
      _track('risk_level_assigned', {'level': level});

  void crisisResourceShown({required int level}) =>
      _track('crisis_resource_shown', {'level': level});

  void userReturnedD1({required String petId}) =>
      _track('user_returned_d1', {'pet_id': petId});

  void userReturnedD7({required String petId}) =>
      _track('user_returned_d7', {'pet_id': petId});

  void userReturnedD21({required String petId}) =>
      _track('user_returned_d21', {'pet_id': petId});

  // ── Internal ──

  void _track(String event, Map<String, dynamic> props) {
    props['timestamp'] = DateTime.now().toIso8601String();
    _mixpanel?.track(event, properties: props);
  }
}
