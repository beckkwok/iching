/// Represents a conversation between the user and the I-Ching system.
class Conversation {
  final int? id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? lastGuaId;

  Conversation({
    this.id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastGuaId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a copy with optional field overrides.
  Conversation copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? lastGuaId,
    bool clearLastGuaId = false,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastGuaId: clearLastGuaId ? null : (lastGuaId ?? this.lastGuaId),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_gua_id': lastGuaId,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as int?,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastGuaId: map['last_gua_id'] as int?,
    );
  }

  @override
  String toString() =>
      'Conversation(id: $id, title: $title, updatedAt: $updatedAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lastGuaId == other.lastGuaId;

  @override
  int get hashCode =>
      Object.hash(id, title, createdAt, updatedAt, lastGuaId);
}
