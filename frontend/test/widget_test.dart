// Basic smoke test for Automated README Architect.

import 'package:flutter_test/flutter_test.dart';

import 'package:automated_readme_architect/main.dart';

void main() {
  testWidgets('App renders splash screen without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ReadmeArchitectApp());

    // Verify the splash screen title text is rendered.
    expect(find.text('README Architect'), findsOneWidget);
    expect(find.text('AI-Powered Documentation Generator'), findsOneWidget);
  });
}
