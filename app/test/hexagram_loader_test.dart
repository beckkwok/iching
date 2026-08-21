import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/gua.dart';
import 'package:app/services/hexagram_loader.dart';

/// Minimal valid hexagram JSON for [code].
String fixtureJson(int code) {
  return '''
  {
    "卦名": "卦$code",
    "卦序": $code,
    "卦象": "䷀（下乾上乾）",
    "卦辭": "卦辭 $code",
    "彖傳": "彖傳 $code",
    "大象傳": "大象傳 $code",
    "爻辭": [],
    "象徵意義": {
      "基本卦象": {"卦體": "下乾上乾", "自然取象": "天", "說明": "說明"},
      "主要象徵": [],
      "生活與占事常見象徵": {},
      "總結": "總結 $code"
    },
    "不同人解讀": [],
    "備註": ""
  }
  ''';
}

void main() {
  final loader = HexagramLoader((code) async => fixtureJson(code));

  test('loadAll parses every hexagram and sorts by guaCode', () async {
    final all = await loader.loadAll();

    expect(all.length, 64);
    for (var i = 0; i < all.length; i++) {
      expect(all[i].guaCode, i + 1);
    }
    // Content parses into a HexagramContent.
    expect(all.first.content, isNotNull);
    expect(all.first.guaName, '卦1');
  });

  test('loadByCode returns the matching hexagram', () async {
    final gua = await loader.loadByCode(23);
    expect(gua, isNotNull);
    expect(gua!.guaCode, 23);
    expect(gua.guaName, '卦23');
  });

  test('loadByCode returns null for a missing code', () async {
    final loader = HexagramLoader((code) async => null);
    final gua = await loader.loadByCode(1);
    expect(gua, isNull);
  });

  test('loadAll skips malformed JSON', () async {
    final loader = HexagramLoader((code) async {
      if (code == 2) return 'not json';
      return fixtureJson(code);
    });
    final all = await loader.loadAll();
    expect(all.length, 63);
    expect(all.any((g) => g.guaCode == 2), isFalse);
  });

  test('Gua model equality ignores content identity', () {
    final a = Gua(
      guaCode: 1,
      guaName: '卦1',
      guaContent: fixtureJson(1),
    );
    final b = Gua(
      guaCode: 1,
      guaName: '卦1',
      guaContent: fixtureJson(1),
    );
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });
}
