import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/data/interpreter_catalog.dart';
import 'package:app/widgets/interpreter_picker.dart';

void main() {
  testWidgets('renders every interpreter and reports the selection', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterpreterPicker(
            selectedKey: InterpreterCatalog.defaultKey,
            onSelected: (key) => selected = key,
          ),
        ),
      ),
    );

    for (final interpreter in InterpreterCatalog.all) {
      expect(find.text(interpreter.name), findsOneWidget);
    }

    await tester.tap(find.text('Practical Advisor'));
    expect(selected, 'practical');
  });
}
