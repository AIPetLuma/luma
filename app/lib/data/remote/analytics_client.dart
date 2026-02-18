/// Analytics event tracking for the 21-day retention experiment.
///
/// Events correspond to the 10 埋点 defined in
/// `p0/03_21天留存实验设计.md`.
class AnalyticsClient {
  // In production, this wraps Mixpanel. For now, a logging stub.
  final void Function(String event, Map<String, dynamic> props)? _track;

  AnalyticsClient({
    void Function(String event, Map<String, dynamic> props)? trackFn,
  }) : _track = trackFn;

  void signupCompleted({required String petId}) =>
      _emit('signup_completed', {'pet_id': petId});

  void sessionStarted({required String petId}) =>
      _emit('session_started', {'pet_id': petId});

  void sessionEnded({required String petId, required int durationSeconds}) =>
      _emit('session_ended', {
        'pet_id': petId,
        'duration_s': durationSeconds,
      });

  void aiDisclosureShown({required String location}) =>
      _emit('ai_disclosure_shown', {'location': location});

  void riskSignalDetected({required int level, required String source}) =>
      _emit('risk_signal_detected', {'level': level, 'source': source});

  void riskLevelAssigned({required int level}) =>
      _emit('risk_level_assigned', {'level': level});

  void crisisResourceShown({required int level}) =>
      _emit('crisis_resource_shown', {'level': level});

  void userReturnedD1({required String petId}) =>
      _emit('user_returned_d1', {'pet_id': petId});

  void userReturnedD7({required String petId}) =>
      _emit('user_returned_d7', {'pet_id': petId});

  void userReturnedD21({required String petId}) =>
      _emit('user_returned_d21', {'pet_id': petId});

  void _emit(String event, Map<String, dynamic> props) {
    _track?.call(event, {
      ...props,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
