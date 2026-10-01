import 'dart:convert';

/// The LLM-derived profile of the user, built from their consultations and
/// feedback. See issue #3.
class AgentMemory {
  final int? id;

  /// A short overall summary of how the user seems to feel.
  final String feeling;

  /// How the user seems to feel, keyed by topic (a `QuestionType` name). Kept
  /// as a JSON map so question types can be added or renamed over time without
  /// a schema change. See issue #26.
  final Map<String, String> feelings;

  /// Facts extracted about the user.
  final List<String> facts;

  /// Preferences / values the user has expressed.
  final List<String> preferences;

  final DateTime updatedAt;

  AgentMemory({
    this.id,
    required this.feeling,
    this.feelings = const {},
    required this.facts,
    required this.preferences,
    required this.updatedAt,
  });

  /// The feeling recorded for [topicKey], or `null`.
  String? feelingFor(String topicKey) => feelings[topicKey];

  bool get isEmpty =>
      feeling.isEmpty &&
      feelings.isEmpty &&
      facts.isEmpty &&
      preferences.isEmpty;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'feeling': feeling,
      'feelings': jsonEncode(feelings),
      'facts': jsonEncode(facts),
      'preferences': jsonEncode(preferences),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory AgentMemory.fromMap(Map<String, dynamic> map) {
    return AgentMemory(
      id: map['id'] as int?,
      feeling: map['feeling'] as String? ?? '',
      feelings: _stringMap(jsonDecode(map['feelings'] as String? ?? '{}')),
      facts: _stringList(jsonDecode(map['facts'] as String? ?? '[]')),
      preferences:
          _stringList(jsonDecode(map['preferences'] as String? ?? '[]')),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static List<String> _stringList(dynamic v) =>
      v is List ? v.whereType<String>().toList() : const [];

  static Map<String, String> _stringMap(dynamic v) {
    if (v is! Map) return const {};
    return {
      for (final entry in v.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  @override
  String toString() => 'AgentMemory(id: $id, feeling: "$feeling")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentMemory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          feeling == other.feeling &&
          _mapEq(feelings, other.feelings) &&
          _listEq(facts, other.facts) &&
          _listEq(preferences, other.preferences) &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        feeling,
        Object.hashAll(
          feelings.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAll(facts),
        Object.hashAll(preferences),
        updatedAt,
      );

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEq(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
