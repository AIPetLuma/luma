import 'dart:convert';

/// Lightweight self model used to keep Luma's identity consistent.
class SelfModel {
  final Map<String, double> values;
  final Map<String, double> traits;
  final List<String> beliefs;
  final double confidence;
  final DateTime updatedAt;

  const SelfModel({
    required this.values,
    required this.traits,
    required this.beliefs,
    required this.confidence,
    required this.updatedAt,
  });

  SelfModel copyWith({
    Map<String, double>? values,
    Map<String, double>? traits,
    List<String>? beliefs,
    double? confidence,
    DateTime? updatedAt,
  }) {
    return SelfModel(
      values: values ?? this.values,
      traits: traits ?? this.traits,
      beliefs: beliefs ?? this.beliefs,
      confidence: confidence ?? this.confidence,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'values': values,
        'traits': traits,
        'beliefs': beliefs,
        'confidence': confidence,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SelfModel.fromJson(Map<String, dynamic> json) {
    return SelfModel(
      values: Map<String, double>.from(
        json['values'] as Map,
      ),
      traits: Map<String, double>.from(
        json['traits'] as Map,
      ),
      beliefs: List<String>.from(json['beliefs'] as List? ?? const []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SelfModel.fromJsonString(String raw) {
    return SelfModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Convert to a prompt fragment for identity consistency.
  String toPromptFragment() {
    final ordered = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordered.take(2).map((e) => e.key).join(', ');
    final beliefText = beliefs.isEmpty ? '' : ' Core beliefs: ${beliefs.join(' ')}';
    return 'Self model: primary values are $top.$beliefText '
        '(confidence ${(confidence * 100).round()}%).';
  }
}
