/// A single recorded consultation: the user's question, the cast hexagram,
/// and the LLM explanation.
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
  final DateTime createdAt;

  Consultation({
    this.id,
    required this.question,
    this.questionTypeLabel,
    required this.hexagramCode,
    required this.hexagramName,
    required this.hexagramContent,
    required this.explanation,
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
      createdAt: DateTime.parse(map['created_at'] as String),
    );
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
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, question, questionTypeLabel, hexagramCode,
      hexagramName, hexagramContent, explanation, createdAt);
}
