import 'dart:convert';

import 'package:app/models/yao_line_type.dart';

/// A single recorded consultation: the user's question, the cast hexagram,
/// the LLM explanation, and (optionally) the user's feedback.
///
/// Also stores the six cast line types and the changed hexagram (issue #47) so
/// the history can show the complete record.
class Consultation {
  final int? id;
  final String question;
  final String? questionTypeLabel;
  final int hexagramCode;
  final String hexagramName;

  /// The raw hexagram JSON (see [HexagramContent]), kept so the detail screen
  /// can be opened from the history.
  final String hexagramContent;

  final String explanation;

  /// The six cast line types (老陰/少陽/少陰/老陽), bottom → top. Empty for
  /// manual lookups and for records saved before issue #47.
  final List<YaoLineType> lineTypes;

  /// The hexagram the changing lines resolve to, if any (issue #47).
  final int? changedHexagramCode;
  final String? changedHexagramName;
  final String? changedHexagramContent;

  /// Feedback reaction key (see `Reaction`), set after the response.
  final String? reaction;

  /// Optional user comment.
  final String? comment;

  final DateTime createdAt;

  Consultation({
    this.id,
    required this.question,
    this.questionTypeLabel,
    required this.hexagramCode,
    required this.hexagramName,
    required this.hexagramContent,
    required this.explanation,
    this.lineTypes = const [],
    this.changedHexagramCode,
    this.changedHexagramName,
    this.changedHexagramContent,
    this.reaction,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'question': question,
      'question_type': questionTypeLabel,
      'hexagram_code': hexagramCode,
      'hexagram_name': hexagramName,
      'hexagram_content': hexagramContent,
      'explanation': explanation,
      'line_types': jsonEncode(lineTypes.map((t) => t.value).toList()),
      'changed_hexagram_code': changedHexagramCode,
      'changed_hexagram_name': changedHexagramName,
      'changed_hexagram_content': changedHexagramContent,
      'reaction': reaction,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      id: map['id'] as int?,
      question: map['question'] as String,
      questionTypeLabel: map['question_type'] as String?,
      hexagramCode: map['hexagram_code'] as int,
      hexagramName: map['hexagram_name'] as String,
      hexagramContent: map['hexagram_content'] as String,
      explanation: map['explanation'] as String,
      lineTypes: _decodeLineTypes(map['line_types']),
      changedHexagramCode: map['changed_hexagram_code'] as int?,
      changedHexagramName: map['changed_hexagram_name'] as String?,
      changedHexagramContent: map['changed_hexagram_content'] as String?,
      reaction: map['reaction'] as String?,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Decode the stored `line_types` JSON array (cast values 6–9).
  static List<YaoLineType> _decodeLineTypes(dynamic value) {
    if (value is! String || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return decoded.whereType<int>().map(YaoLineType.fromValue).toList();
    } on FormatException {
      return const [];
    }
  }

  static bool _lineTypesEqual(List<YaoLineType> a, List<YaoLineType> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Consultation(id: $id, hexagram: $hexagramCode, question: "$question")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Consultation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          question == other.question &&
          questionTypeLabel == other.questionTypeLabel &&
          hexagramCode == other.hexagramCode &&
          hexagramName == other.hexagramName &&
          hexagramContent == other.hexagramContent &&
          explanation == other.explanation &&
          _lineTypesEqual(lineTypes, other.lineTypes) &&
          changedHexagramCode == other.changedHexagramCode &&
          changedHexagramName == other.changedHexagramName &&
          changedHexagramContent == other.changedHexagramContent &&
          reaction == other.reaction &&
          comment == other.comment &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        question,
        questionTypeLabel,
        hexagramCode,
        hexagramName,
        hexagramContent,
        explanation,
        Object.hashAll(lineTypes),
        changedHexagramCode,
        changedHexagramName,
        changedHexagramContent,
        reaction,
        comment,
        createdAt,
      );
}
