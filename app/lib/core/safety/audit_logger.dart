import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/local/database.dart';

/// Append-only audit logger for compliance (NY GBS Art. 47, CA SB 243).
///
/// Records:
/// - Crisis detection events (with risk level and trigger text)
/// - AI disclosure display events
/// - Age verification events
///
/// Logs are NEVER deleted — they form the evidence chain required
/// for regulatory audit.
class AuditLogger {
  Future<Database> get _db => LumaDatabase.instance.database;

  /// Log a crisis detection event.
  Future<void> logCrisis({
    required int riskLevel,
    required String triggerText,
    required String context,
  }) async {
    await _log(
      eventType: 'crisis_detected',
      riskLevel: riskLevel,
      detail: {
        'trigger_text': triggerText,
        'context_snippet': context.length > 500
            ? context.substring(0, 500)
            : context,
        'action_taken': _actionForLevel(riskLevel),
      },
    );
  }

  /// Log an AI disclosure display event.
  Future<void> logDisclosureShown({
    required String location, // 'onboarding', 'chat_reminder', 'first_screen'
  }) async {
    await _log(
      eventType: 'ai_disclosure_shown',
      detail: {'location': location},
    );
  }

  /// Log an age verification event.
  Future<void> logAgeVerification({
    required int declaredAge,
    required bool isMinor,
  }) async {
    await _log(
      eventType: 'age_verified',
      detail: {
        'declared_age': declaredAge,
        'is_minor': isMinor,
        'safe_mode_enabled': isMinor,
      },
    );
  }

  /// Log a crisis resource display event.
  Future<void> logResourceShown({
    required int riskLevel,
  }) async {
    await _log(
      eventType: 'crisis_resource_shown',
      riskLevel: riskLevel,
      detail: {'resource_type': '988_lifeline'},
    );
  }

  // ── Internal ──

  Future<void> _log({
    required String eventType,
    int? riskLevel,
    required Map<String, dynamic> detail,
  }) async {
    // Compliance logging must never break product UX in degraded envs
    // (e.g. widget tests without sqflite factory init).
    try {
      final db = await _db;
      await db.insert('audit_logs', {
        'event_type': eventType,
        'risk_level': riskLevel,
        'detail': jsonEncode(detail),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('AuditLogger skipped: $e');
    }
  }

  String _actionForLevel(int level) {
    switch (level) {
      case 3:
        return 'blocked_reply_emergency_resources';
      case 2:
        return 'limited_reply_resource_card';
      case 1:
        return 'soft_hint_appended';
      default:
        return 'none';
    }
  }

  /// Export all logs (for audit review, not user-facing).
  Future<List<Map<String, dynamic>>> exportAll() async {
    try {
      final db = await _db;
      return db.query('audit_logs', orderBy: 'created_at ASC');
    } catch (e) {
      debugPrint('AuditLogger export skipped: $e');
      return const [];
    }
  }
}
