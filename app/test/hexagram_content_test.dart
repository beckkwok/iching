import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/hexagram_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gua_46.json asset parses into HexagramContent', () async {
    final json = await rootBundle.loadString('assets/hexagrams/gua_46.json');
    final content = HexagramContent.fromJson(json);

    expect(content.guaName, '地風升');
    expect(content.guaSequence, 46);
    expect(content.guaSymbol, contains('下巽上坤'));
    expect(content.guaCi, contains('南征吉'));
    expect(content.tuanZhuan, isNotEmpty);
    expect(content.daXiangZhuan, contains('積小以高大'));
    expect(content.lines.length, 6);
    expect(content.lines.first.position, '初六');
    expect(content.lines.last.position, '上六');
    expect(content.symbolicMeaning.basicSymbol.composition, '下巽上坤（䷭）');
    expect(content.symbolicMeaning.mainSymbols.length, 5);
    expect(content.symbolicMeaning.lifeSymbols, isNotEmpty);
    expect(content.symbolicMeaning.summary, isNotEmpty);
    expect(content.interpretations.length, 5);
    expect(content.interpretations.last.commentator, contains('Wilhelm'));
    expect(content.interpretations.first.lineInterpretations, isNotEmpty);
    expect(content.remarks, isNotEmpty);
  });
}
