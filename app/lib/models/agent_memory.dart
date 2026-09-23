import 'dart:convert';

/// The LLM-derived profile of the user, built from their consultations and
/// feedback. See issue #3.
class AgentMemory {
  final int? id;

  /// A short summary of how the user seems to feel about their topics.
  final String feeling;

  /// Facts extracted about the user.
  final List<String> facts;

  /// Preferences / values the user has expressed.
  final List<String> preferences;

  final DateTime updatedAt;

  AgentMemory({
    this.id,
    required this.feeling,
    required this.facts,
    required this.preferences,
    required this.updatedAt,
  });

  bool get isEmpty => feeling.isEmpty && facts.isEmpty && preferences.isEmpty;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'feeling': feeling,
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
      facts: _stringList(jsonDecode(map['facts'] as String? ?? '[]')),
      preferences:
          _stringList(jsonDecode(map['preferences'] as String? ?? '[]')),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static List<String> _stringList(dynamic v) =>
      v is List ? v.whereType<String>().toList() : const [];

  @override
  String toString() => 'AgentMemory(id: $id, feeling: "$feeling")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentMemory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          feeling == other.feeling &&
          _listEq(facts, other.facts) &&
          _listEq(preferences, other.preferences) &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
      id, feeling, Object.hashAll(facts), Object.hashAll(preferences), updatedAt);

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
