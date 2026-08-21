import 'hexagram_content.dart';

/// Represents a single Gua (hexagram), loaded from a JSON asset.
class Gua {
  final int guaCode;
  final String guaName;

  /// The raw JSON string (see [HexagramContent]) describing this hexagram.
  final String guaContent;

  /// Lazily parsed [guaContent]. Null if the JSON fails to parse.
  HexagramContent? _parsed;

  Gua({
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

  @override
  String toString() => 'Gua(code: $guaCode, name: $guaName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gua &&
          runtimeType == other.runtimeType &&
          guaCode == other.guaCode &&
          guaName == other.guaName &&
          guaContent == other.guaContent;

  @override
  int get hashCode => Object.hash(guaCode, guaName, guaContent);
}
