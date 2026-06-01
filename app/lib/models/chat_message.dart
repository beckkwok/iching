/// Represents a single message in the chat conversation.
enum MessageSender { user, system }

class ChatMessage {
  /// Unique UI identifier (e.g. "msg_0").
  final String id;

  /// Database auto-increment ID (null before first persist).
  final int? dbId;

  /// ID of the conversation this message belongs to.
  final int? conversationId;

  /// The message text content.
  final String text;

  /// Whether this message is from the user or the system.
  final MessageSender sender;

  /// When the message was created.
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.dbId,
    this.conversationId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a copy with optional field overrides.
  ChatMessage copyWith({
    String? id,
    int? dbId,
    int? conversationId,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool clearDbId = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      dbId: clearDbId ? null : (dbId ?? this.dbId),
      conversationId: conversationId ?? this.conversationId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Whether this message is from the user.
  bool get isUser => sender == MessageSender.user;

  /// Whether this message is from the system.
  bool get isSystem => sender == MessageSender.system;

  /// Serialize to a map for database insertion.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'sender': sender.name,
      'message': text,
      'timestamp': timestamp.toIso8601String(),
    };
    if (dbId != null) {
      map['id'] = dbId;
    }
    if (conversationId != null) {
      map['conversation_id'] = conversationId;
    }
    return map;
  }

  /// Deserialize from a database row map.
  factory ChatMessage.fromDbMap(Map<String, dynamic> map) {
    final senderStr = map['sender'] as String;
    return ChatMessage(
      id: 'db_${map['id']}',
      dbId: map['id'] as int?,
      conversationId: map['conversation_id'] as int?,
      text: map['message'] as String,
      sender: senderStr == 'user' ? MessageSender.user : MessageSender.system,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'ChatMessage(id: $id, sender: ${sender.name}, text: "$text")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dbId == other.dbId &&
          conversationId == other.conversationId &&
          text == other.text &&
          sender == other.sender &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      Object.hash(id, dbId, conversationId, text, sender, timestamp);
}
