/// A single recorded consultation: the user's question, the cast hexagram,
/// the LLM explanation, and (optionally) the user's feedback.
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

  /// Feedback rating (1-5, where 5 = very satisfied), set after the response.
  final int? rating;

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
    this.rating,
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
      'rating': rating,
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
      rating: map['rating'] as int?,
      comment: map['comment'] as String?,
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
          rating == other.rating &&
          comment == other.comment &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, question, questionTypeLabel, hexagramCode,
      hexagramName, hexagramContent, explanation, rating, comment, createdAt);
}
