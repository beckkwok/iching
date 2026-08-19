import 'hexagram_content.dart';

/// Represents a single Gua (hexagram) entry in the database.
class Gua {
  final int? id;
  final int guaCode;
  final String guaName;

  /// The raw JSON string (see [HexagramContent]) describing this hexagram.
  final String guaContent;

  /// Lazily parsed [guaContent]. Null if the JSON fails to parse.
  HexagramContent? _parsed;

  Gua({
    this.id,
    required this.guaCode,
    required this.guaName,
    required this.guaContent,
  });

  /// Parse [guaContent] into a [HexagramContent], caching the result.
  /// Returns `null` if [guaContent] is not valid hexagram JSON.
  HexagramContent? get content {
    _parsed ??= _tryParse();
    return _parsed;
  }

  HexagramContent? _tryParse() {
    try {
      return HexagramContent.fromJson(guaContent);
    } catch (_) {
      return null;
    }
  }

  Gua copyWith({
    int? id,
    int? guaCode,
    String? guaName,
    String? guaContent,
  }) {
    return Gua(
      id: id ?? this.id,
      guaCode: guaCode ?? this.guaCode,
      guaName: guaName ?? this.guaName,
      guaContent: guaContent ?? this.guaContent,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'gua_code': guaCode,
      'gua_name': guaName,
      'gua_content': guaContent,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Gua.fromMap(Map<String, dynamic> map) {
    return Gua(
      id: map['id'] as int?,
      guaCode: map['gua_code'] as int,
      guaName: map['gua_name'] as String,
      guaContent: map['gua_content'] as String,
    );
  }

  @override
  String toString() => 'Gua(id: $id, code: $guaCode, name: $guaName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gua &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          guaCode == other.guaCode &&
          guaName == other.guaName &&
          guaContent == other.guaContent;

  @override
  int get hashCode => Object.hash(id, guaCode, guaName, guaContent);
}
