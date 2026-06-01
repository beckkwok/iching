/// Represents a single Gua (hexagram) entry in the database.
class Gua {
  final int? id;
  final int guaCode;
  final String guaName;
  final String guaContent;
  final String guaSummary;
  final String source;

  Gua({
    this.id,
    required this.guaCode,
    required this.guaName,
    required this.guaContent,
    required this.guaSummary,
    required this.source,
  });

  Gua copyWith({
    int? id,
    int? guaCode,
    String? guaName,
    String? guaContent,
    String? guaSummary,
    String? source,
  }) {
    return Gua(
      id: id ?? this.id,
      guaCode: guaCode ?? this.guaCode,
      guaName: guaName ?? this.guaName,
      guaContent: guaContent ?? this.guaContent,
      guaSummary: guaSummary ?? this.guaSummary,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'gua_code': guaCode,
      'gua_name': guaName,
      'gua_content': guaContent,
      'gua_summary': guaSummary,
      'source': source,
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
      guaSummary: map['gua_summary'] as String,
      source: map['source'] as String,
    );
  }

  @override
  String toString() =>
      'Gua(id: $id, code: $guaCode, name: $guaName, source: $source)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gua &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          guaCode == other.guaCode &&
          guaName == other.guaName &&
          guaContent == other.guaContent &&
          guaSummary == other.guaSummary &&
          source == other.source;

  @override
  int get hashCode =>
      Object.hash(id, guaCode, guaName, guaContent, guaSummary, source);
}
