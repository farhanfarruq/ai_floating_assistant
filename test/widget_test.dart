// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_floating_assistant/main.dart';

void main() {
  testWidgets('App loads without crash', (WidgetTester tester) async {
    // Build our app - wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: AiFloatingAssistantApp(),
      ),
    );

    // Verify that the app renders the title
    expect(find.text('AI Floating Assistant'), findsOneWidget);
  });
}
