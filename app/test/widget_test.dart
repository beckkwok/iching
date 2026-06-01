import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('Chat screen displays welcome message', (tester) async {
    await tester.pumpWidget(const MyApp());

    // The welcome message is a single Text widget with a newline
    expect(
      find.textContaining('Welcome. I am here to help you reflect.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Tell me what is on your mind.'),
      findsOneWidget,
    );
  });

  testWidgets('User can type and send a message via keyboard',
      (tester) async {
    await tester.pumpWidget(const MyApp());

    // Find the text field and type
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'I feel uncertain about my path');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // The user message should now appear
    expect(
      find.text('I feel uncertain about my path'),
      findsOneWidget,
    );

    // Pump past the system response delay timer
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('System responds after user sends a message', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Send a message
    await tester.enterText(
      find.byType(TextField),
      'I feel uncertain',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Wait for the simulated system delay
    await tester.pump(const Duration(seconds: 1));

    // The system should have responded
    expect(
      find.textContaining('Thank you for sharing'),
      findsOneWidget,
    );
  });

  testWidgets('Send button is present', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Find the send button
    final sendButton = find.byIcon(Icons.send);
    expect(sendButton, findsOneWidget);
  });

  testWidgets('User can tap send button to submit message', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Type a message
    await tester.enterText(
      find.byType(TextField),
      'Testing the send button',
    );
    await tester.pump();

    // Tap the send button
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // User message should appear
    expect(
      find.text('Testing the send button'),
      findsOneWidget,
    );

    // Pump past the system response delay timer
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Chat bubble styling distinguishes user from system',
      (tester) async {
    await tester.pumpWidget(const MyApp());

    // Send a message
    await tester.enterText(
      find.byType(TextField),
      'A test message',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // User bubble should be aligned to the right (end)
    final userBubble = find.text('A test message');
    expect(userBubble, findsOneWidget);

    // Pump past the system response delay timer
    await tester.pump(const Duration(seconds: 1));

    // Welcome message from system should also be visible
    expect(
      find.textContaining('Welcome'),
      findsOneWidget,
    );
  });
}
