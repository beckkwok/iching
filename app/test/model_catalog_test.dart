import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/model_catalog.dart';

void main() {
  group('ModelCatalog', () {
    test('exposes at least one model', () {
      expect(ModelCatalog.all, isNotEmpty);
    });

    test('model keys are unique', () {
      final keys = ModelCatalog.all.map((m) => m.key).toSet();
      expect(keys.length, ModelCatalog.all.length);
    });

    test('model filenames are unique', () {
      final filenames = ModelCatalog.all.map((m) => m.filename).toSet();
      expect(filenames.length, ModelCatalog.all.length);
    });

    test('every model has complete metadata', () {
      for (final model in ModelCatalog.all) {
        expect(model.key, isNotEmpty, reason: 'key');
        expect(model.modelFamily, isNotEmpty, reason: 'modelFamily');
        expect(model.bestFor, isNotEmpty, reason: 'bestFor');
        expect(model.language, isNotEmpty, reason: 'language');
        expect(model.sizeLabel, isNotEmpty, reason: 'sizeLabel');
        expect(model.downloadUrl, startsWith('https://'), reason: 'downloadUrl');
        expect(model.filename, endsWith('.litertlm'), reason: 'filename');
      }
    });

    test('byKey returns the matching model', () {
      final first = ModelCatalog.all.first;
      expect(ModelCatalog.byKey(first.key), same(first));
    });

    test('byKey returns null for an unknown key', () {
      expect(ModelCatalog.byKey('does_not_exist'), isNull);
    });

    test('defaultModel resolves to the configured default key', () {
      expect(ModelCatalog.byKey(ModelCatalog.defaultModelKey), isNotNull);
      expect(ModelCatalog.defaultModel.key, ModelCatalog.defaultModelKey);
      // Qwen3-0.6B is the production default (see issue #4).
      expect(ModelCatalog.defaultModelKey, 'qwen3');
    });
  });
}
