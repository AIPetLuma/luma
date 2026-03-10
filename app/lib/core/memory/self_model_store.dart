import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/local/memory_dao.dart';
import '../../data/models/memory_entry.dart';
import '../engine/reflection_engine.dart';
import '../identity/self_model.dart';

/// Persists self model snapshots and reflection records.
class SelfModelStore {
  static const selfModelPrefix = 'SELF_MODEL:';
  static const reflectionPrefix = 'REFLECTION:';

  final MemoryDao _dao;

  SelfModelStore({required MemoryDao dao}) : _dao = dao;

  Future<SelfModel?> load(String petId) async {
    final rows = await _dao.getLongTermByPrefix(
      petId,
      selfModelPrefix,
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first.content.substring(selfModelPrefix.length);
    try {
      return SelfModel.fromJsonString(raw);
    } catch (e) {
      debugPrint('SelfModelStore: parse failed ($e).');
      return null;
    }
  }

  Future<void> save(String petId, SelfModel model) async {
    await _dao.insert(
      MemoryEntry(
        petId: petId,
        level: MemoryLevel.longTerm,
        content: '$selfModelPrefix${model.toJsonString()}',
        importance: 0.95,
        createdAt: model.updatedAt,
      ),
    );
  }

  Future<void> recordReflection(String petId, ReflectionRecord record) async {
    final payload = jsonEncode(record.toJson());
    await _dao.insert(
      MemoryEntry(
        petId: petId,
        level: MemoryLevel.longTerm,
        content: '$reflectionPrefix$payload',
        importance: 0.6,
        createdAt: record.createdAt,
      ),
    );
  }
}
